#!/bin/bash
# Regression test for redmine#44240: plugin/theme assets installed with mtimes
# OLDER than the existing Propshaft manifest must still be compiled into the
# manifest and served.
#
# Files extracted from a zip/tarball, or copied with rsync -a, keep their
# original timestamps. Before Redmine 6.1.6 / 7.0.3, redmine_detect_update only
# recompiled when an asset file was newer than the manifest, so such files were
# skipped and their URLs 404'd. Redmine now compares manifest contents instead,
# which this image relies on (the entrypoint no longer forces a recompile).
#
# The themes + plugins live in a throwaway named volume, so the manifest (under
# the data volume) persists across container recreation. Every file added is
# backdated to 2020. Each asset is checked by digest in .manifest.json AND by
# fetching it over HTTP, so a pass means it is actually served.
#
#   1. clean boot, no themes/plugins              -> baseline manifest
#   2. add theme, recreate                        -> theme compiled + served
#   3. change theme content, recreate             -> new content served
#   4. add plugin asset, recreate                 -> plugin asset served, theme kept
#   5. add 2nd theme, docker restart (same ctr)   -> 2nd theme served
#   6. remove 1st theme, recreate                 -> 1st theme dropped, 2nd kept
#
# Usage:  ./test/asset-detect-update.sh
# Env overrides:
#   IMAGE  (default sameersbn/redmine:<VERSION from repo VERSION file>)
#   PORT   (default 10092 — smoke-compose.sh uses 10083 and
#           theme-recompile-ordering.sh 10091, so these can coexist)
#   FUNCS  (optional path to an assets/runtime/functions file to bind-mount
#           over the image's copy, to try entrypoint changes without a rebuild)
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO" || exit 1

IMAGE="${IMAGE:-sameersbn/redmine:$(cat VERSION)}"
PORT="${PORT:-10092}"
FUNCS="${FUNCS:-}"
BASE="http://localhost:${PORT}"
CONTAINER="asset-detect-update"
VOL="asset-detect-update-data"
MANIFEST=/home/redmine/redmine/public/assets/.manifest.json
OLD=202001010000
fails=0

cleanup() {
  docker rm -f "$CONTAINER" >/dev/null 2>&1
  docker volume rm -f "$VOL" >/dev/null 2>&1
}
trap cleanup EXIT

die() { echo "FATAL: $1"; docker logs "$CONTAINER" 2>&1 | tail -30; exit 2; }
check() {
  if eval "$2"; then echo "   ok:   $1"; else echo "   FAIL: $1"; fails=$((fails+1)); fi
}

vol_sh() { docker run --rm -v "${VOL}:/data" busybox sh -c "$1"; }
# backdate everything under /data/<dir> so it is older than the manifest
age() { vol_sh "find /data/$1 -exec touch -t $OLD {} +"; }

waitup() {
  local i
  for i in $(seq 1 120); do
    curl -sf -o /dev/null -m 5 "$BASE/up" && return 0
    docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null | grep -q true \
      || die "container exited"
    sleep 3
  done
  die "/up never returned 200"
}

# `docker rm -f` + `docker run` gives a fresh container filesystem against the
# persistent data volume — equivalent to `docker compose up -d --force-recreate`.
recreate_container() {
  local mount=()
  [ -n "$FUNCS" ] && mount=(-v "$(readlink -f "$FUNCS"):/etc/docker-redmine/runtime/functions:ro")
  docker rm -f "$CONTAINER" >/dev/null 2>&1
  docker run -d --name "$CONTAINER" -p "${PORT}:80" \
    -e DB_ADAPTER=sqlite3 -e DB_NAME=db.sqlite3 \
    -e REDMINE_PORT="${PORT}" -e REDMINE_HTTPS=false -e REDMINE_RELATIVE_URL_ROOT= \
    -e SMTP_ENABLED=false -e IMAP_ENABLED=false \
    -v "${VOL}:/home/redmine/data" "${mount[@]}" \
    "$IMAGE" >/dev/null || die "docker run failed"
  waitup
}

# Digested path of a logical asset path in the manifest; empty if absent.
# Themes are keyed "themes/<dir>/<file>", plugins "plugin_assets/<id>/<file>".
digest() {
  docker exec "$CONTAINER" cat "$MANIFEST" 2>/dev/null | python3 -I -c '
import sys, json
v = json.load(sys.stdin).get(sys.argv[1])
print((v.get("digested_path") if isinstance(v, dict) else v) or "")' "$1"
}

# served <logical path> <marker>: asset is in the manifest and its URL returns the marker
served() {
  local d; d=$(digest "$1"); [ -n "$d" ] || return 1
  curl -sf "$BASE/assets/$d" | grep -q "$2"
}

echo ">>> redmine#44240 asset-detect regression test (image ${IMAGE}${FUNCS:+, functions ${FUNCS}})"
cleanup
docker volume create "$VOL" >/dev/null || die "could not create volume"

echo "== Step 1: clean boot =="
recreate_container
check "manifest exists" '[ -n "$(digest application.css)" ]'
check "oldtheme not yet present" '[ -z "$(digest themes/oldtheme/application.css)" ]'

echo "== Step 2: add theme with old mtimes, recreate =="
vol_sh 'mkdir -p /data/themes/oldtheme/stylesheets
  echo "/* oldtheme v1 */ body{color:#123}" > /data/themes/oldtheme/stylesheets/application.css'
age themes
recreate_container
check "oldtheme v1 in manifest and served" 'served themes/oldtheme/application.css "oldtheme v1"'

echo "== Step 3: change theme content, keep old mtimes, recreate =="
d1=$(digest themes/oldtheme/application.css)
vol_sh 'echo "/* oldtheme v2 */ body{color:#456}" > /data/themes/oldtheme/stylesheets/application.css'
age themes
recreate_container
check "digest changed" '[ "$(digest themes/oldtheme/application.css)" != "$d1" ]'
check "oldtheme v2 served" 'served themes/oldtheme/application.css "oldtheme v2"'

echo "== Step 4: add plugin asset with old mtimes, recreate =="
vol_sh 'mkdir -p /data/plugins/repro_plugin/assets/stylesheets
  {
    echo "Redmine::Plugin.register :repro_plugin do"
    echo "  name \"Repro Plugin\""
    echo "  version \"0.0.1\""
    echo "end"
  } > /data/plugins/repro_plugin/init.rb
  echo "/* repro plugin css */" > /data/plugins/repro_plugin/assets/stylesheets/repro.css'
age plugins
recreate_container
check "plugin asset in manifest and served" 'served plugin_assets/repro_plugin/repro.css "repro plugin css"'
check "oldtheme still served" 'served themes/oldtheme/application.css "oldtheme v2"'

echo "== Step 5: add 2nd theme with old mtimes, docker restart (same container) =="
vol_sh 'mkdir -p /data/themes/oldtheme2/stylesheets
  echo "/* oldtheme2 */" > /data/themes/oldtheme2/stylesheets/application.css'
age themes
docker restart "$CONTAINER" >/dev/null || die "restart failed"
sleep 5
waitup
check "oldtheme2 in manifest and served" 'served themes/oldtheme2/application.css "oldtheme2"'

echo "== Step 6: remove 1st theme, recreate =="
vol_sh 'rm -rf /data/themes/oldtheme'
recreate_container
check "oldtheme gone from manifest" '[ -z "$(digest themes/oldtheme/application.css)" ]'
check "oldtheme2 still served" 'served themes/oldtheme2/application.css "oldtheme2"'

if [ "$fails" -eq 0 ]; then
  echo "PASS: asset-detect update (redmine#44240)"
  exit 0
fi
echo "FAIL: ${fails} check(s) failed"
exit 1
