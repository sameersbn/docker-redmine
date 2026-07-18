#!/bin/bash
# Regression test for the REDMINE_RELATIVE_URL_ROOT asset-precompile bug:
# compiled CSS url() refs must honour the sub-URI. Boots the image with
# `app:init` under a sub-URI (sqlite3, single container) and asserts the
# compiled application CSS has no bare /assets/ refs and >0 ${SUBURI}/assets/.
#
# Usage: ./test/relative-url-root-precompile.sh [image]
#   image  docker image to test (default: sameersbn/redmine:<VERSION file>, the
#          tag the compose files build/publish)
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SUBURI="/redmine"

IMAGE="${1:-sameersbn/redmine:$(cat "$REPO/VERSION")}"

C="relurl-precompile-test-$$"
OUT="$(mktemp -d)"
cleanup() { docker rm -f "$C" >/dev/null 2>&1; rm -rf "$OUT"; }
trap cleanup EXIT

echo ">>> Testing image: $IMAGE  (REDMINE_RELATIVE_URL_ROOT=$SUBURI)"
docker rm -f "$C" >/dev/null 2>&1

# app:init -> install_plugins -> redmine:plugins:migrate boots Rails and
# triggers the precompile this bug lives in.
if ! docker run --name "$C" \
      -e DB_ADAPTER=sqlite3 \
      -e REDMINE_RELATIVE_URL_ROOT="$SUBURI" \
      "$IMAGE" app:init > "$OUT/init.log" 2>&1; then
  echo "FAIL: app:init did not complete cleanly"; tail -20 "$OUT/init.log"; exit 1
fi

# public/assets is a symlink into the data volume; read the real path.
docker cp "$C:/home/redmine/data/tmp/assets/." "$OUT/assets/" >/dev/null 2>&1

shopt -s nullglob
css=("$OUT"/assets/application-*.css)
if [ ${#css[@]} -eq 0 ]; then
  echo "FAIL: no compiled application-*.css found in the container"; exit 1
fi
echo "    compiled CSS: $(basename "${css[0]}")"

# Bare "/assets/..." is the bug; "${SUBURI}/assets/..." is correct.
bare=$(grep -hoE 'url\(["'"'"']?/assets/'        "${css[@]}" | wc -l | tr -d ' ')
sub=$( grep -hoE "url\\([\"']?${SUBURI}/assets/" "${css[@]}" | wc -l | tr -d ' ')
echo "    bare  url(/assets/...) refs        : $bare (want 0)"
echo "    sub-URI url(${SUBURI}/assets/...) refs : $sub (want >0)"

if [ "$bare" -ne 0 ] || [ "$sub" -eq 0 ]; then
  echo "FAIL: compiled CSS ignores REDMINE_RELATIVE_URL_ROOT"
  echo "      sample offending refs:"
  grep -hoE 'url\(["'"'"']?/assets/[^)]*\)' "${css[@]}" | sort -u | head -5 | sed 's/^/        /'
  exit 1
fi

echo "PASS: every compiled url() asset ref uses the ${SUBURI}/assets/ prefix"
