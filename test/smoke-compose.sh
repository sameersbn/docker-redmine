#!/bin/bash
# Smoke-test docker-compose file(s) with throwaway volumes (no sudo required).
#
# For each compose file: layer the test overrides that swap the persistent bind
# mounts for throwaway named volumes (and mount the repo certs), build + `up -d`,
# wait for /up, log in as admin, verify the versions reported on /admin/info,
# then `down -v`.
#
# Overrides (in test/), merged by Compose on top of each compose file:
#   docker-compose.testvols.yml    - redmine data/logs volumes + certs (all files)
#   docker-compose.postgresvols.yml- postgresql data volume (postgres-backed files)
#   docker-compose.mariadbvols.yml - mariadb data volume
#   docker-compose.mysqlvols.yml   - mysql data volume
# sqlite3 keeps its db inside the redmine data volume, so needs no db override.
#
# Usage:
#   ./test/smoke-compose.sh [compose-file ...]
# With no arguments, tests the locally-runnable compose files (incl. ssl).
# Env overrides:
#   PORT           (default 10083)
#   ADMIN_PW       (default test1234)
#   SMOKE_NO_BUILD (default unset) - if set, reuse the already-built
#                  sameersbn/redmine:<version> image instead of `up --build`
#                  (CI builds+loads it once, then runs this to test that exact image).
#
# docker-compose-aws.yml is skipped by default (needs an external AWS RDS).
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO" || exit 1

# shellcheck source=test/redmine_curl.sh
source "$REPO/test/redmine_curl.sh"

PORT="${PORT:-10083}"
BASE="http://localhost:${PORT}"
ADMIN_PW="${ADMIN_PW:-test1234}"
TESTVOLS="test/docker-compose.testvols.yml"
# Build the image per-stack unless SMOKE_NO_BUILD is set (then reuse a pre-built one).
BUILD_FLAG="--build"; [ -n "${SMOKE_NO_BUILD:-}" ] && BUILD_FLAG=""

# Expected Redmine version comes from the Dockerfile (source of truth), e.g. 7.0.0
EXPECT_REDMINE="$(grep -E '^\s*ENV REDMINE_VERSION=' Dockerfile | head -1 | sed -E 's/.*REDMINE_VERSION=([0-9.]+).*/\1/')"

# certs are mounted into the container by the testvols override; make sure they exist
if [ ! -f certs/redmine.crt ] || [ ! -f certs/redmine.key ]; then
  echo "certs missing -> make generate-certs"; make generate-certs >/dev/null 2>&1 || true
fi

FILES=("$@")
if [ ${#FILES[@]} -eq 0 ]; then
  FILES=(docker-compose.yml docker-compose-mariadb.yml docker-compose-mysql.yml \
         docker-compose-memcached.yml docker-compose-sqlite3.yml docker-compose-ssl.yml)
fi

results=()

# Echo the db-specific volume override (-f ...) for a given compose file, if any.
db_override() {
  case "$1" in
    *mariadb*) echo "-f test/docker-compose.mariadbvols.yml" ;;
    *mysql*)   echo "-f test/docker-compose.mysqlvols.yml" ;;
    *sqlite*)  echo "" ;;                                   # db lives in the redmine data volume
    *)         echo "-f test/docker-compose.postgresvols.yml" ;;  # postgres: default, memcached, ssl
  esac
}

smoke_one() {
  local f="$1"
  [ -f "$f" ] || { echo ">>> $f : MISSING, skipping"; results+=("$f|SKIP|file not found"); return; }
  local proj; proj="smoke-$(echo "$f" | tr './' '__')"
  local DC
  # shellcheck disable=SC2086  # db_override output is intentionally word-split into -f flags
  DC="docker compose -p $proj -f $f -f $TESTVOLS $(db_override "$f")"

  # HTTPS compose files publish :443 - hit /up over https on that mapped host port
  local url="$BASE" curlk=""
  if grep -qE '"[0-9]+:443"' "$f"; then
    local hp; hp=$(grep -oE '"[0-9]+:443"' "$f" | head -1 | sed -E 's/"([0-9]+):443"/\1/')
    url="https://localhost:${hp}"; curlk="-k"
  fi

  echo "=================================================================="
  echo ">>> $f  (project $proj, base $url)"
  $DC down -v --remove-orphans >/dev/null 2>&1
  if ! $DC up -d $BUILD_FLAG >/tmp/smoke_up.log 2>&1; then
    echo "   UP FAILED"; tail -6 /tmp/smoke_up.log
    results+=("$f|FAIL|up failed")
    $DC down -v --remove-orphans >/dev/null 2>&1; return
  fi

  local code=000 i
  for i in $(seq 1 80); do
    code=$(curl -s $curlk -o /dev/null -w "%{http_code}" "$url/up" 2>/dev/null || echo 000)
    [ "$code" = "200" ] && break
    sleep 3
  done
  if [ "$code" != "200" ]; then
    echo "   /up never returned 200 (last=$code)"; $DC logs redmine 2>/dev/null | tail -15
    results+=("$f|FAIL|/up=$code")
    $DC down -v --remove-orphans >/dev/null 2>&1; return
  fi
  echo "   /up 200 OK"

  # set a known admin password using the in-container helper script
  $DC exec -T redmine redmine-admin-password "$ADMIN_PW" >/dev/null 2>&1

  local cookie; cookie="$(mktemp)"
  local login redmine_version rails_version errs
  # shellcheck disable=SC2086  # $curlk is intentionally word-split (empty or -k)
  login=$(redmine_login "$url" "$cookie" admin "$ADMIN_PW" $curlk)
  # shellcheck disable=SC2086
  redmine_get "$url" "$cookie" /admin/info $curlk > /tmp/smoke_info.html
  redmine_version=$(sed -e 's/<[^>]*>/ /g' /tmp/smoke_info.html | grep -i "redmine version" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+[.a-z]*' | head -1)
  rails_version=$(sed -e 's/<[^>]*>/ /g' /tmp/smoke_info.html | grep -i "rails version"   | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  errs=$(grep -oE 'icon-error' /tmp/smoke_info.html | wc -l | tr -d ' ')
  echo "   login=$login  Redmine=$redmine_version  Rails=$rails_version  icon-error=$errs (2 expected: pandoc optional, async queue adapter)"

  local verdict="PASS"
  [ "$login" = "302" ] || verdict="FAIL(login=$login)"
  case "$redmine_version" in "$EXPECT_REDMINE"|"$EXPECT_REDMINE".*) ;; *) verdict="FAIL(redmine=$redmine_version want=$EXPECT_REDMINE)";; esac
  echo "   => $verdict"
  results+=("$f|$verdict|Redmine=$redmine_version Rails=$rails_version errs=$errs")

  $DC down -v --remove-orphans >/dev/null 2>&1
  rm -f "$cookie"
}

echo "Expected Redmine version (from Dockerfile): ${EXPECT_REDMINE:-<unknown>}"
for f in "${FILES[@]}"; do smoke_one "$f"; done

echo ""
echo "================= MATRIX SUMMARY ================="
printf "%-32s %-24s %s\n" "COMPOSE FILE" "VERDICT" "DETAIL"
fail=0
for r in "${results[@]}"; do
  IFS='|' read -r f v d <<< "$r"
  printf "%-32s %-24s %s\n" "$f" "$v" "$d"
  case "$v" in PASS) ;; SKIP) ;; *) fail=1;; esac
done
exit $fail
