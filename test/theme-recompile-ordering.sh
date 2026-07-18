#!/bin/bash
# Regression test for the theme-recompile ordering bug.
#
# Bug: when a plugin's content changes but a custom theme's content does not,
# the next FRESH-container boot recompiles Propshaft assets in install_plugins()
# (via `redmine:plugins:migrate` booting Rails against a deleted manifest)
# BEFORE install_themes() has rsynced the custom theme into place. The manifest
# is therefore written without the custom theme, and because the theme's own
# sha1 is unchanged install_themes() never forces a second recompile -> every
# custom-theme asset 404s until something unrelated forces a full rebuild.
#
# The theme + plugin live in a throwaway named volume (so the manifest, which
# lives under the data volume, persists across container recreation, while the
# container filesystem — where themes/ is rsynced each boot — starts fresh).
# Named volumes avoid host-side ownership/sudo problems on cleanup.
#
#   1. clean boot           -> asserts the theme IS in the manifest (baseline)
#   2. plugin-only recreate -> asserts the theme is STILL in the manifest
# Step 2 fails on buggy code and passes once the ordering is fixed.
#
# Usage:  ./test/theme-recompile-ordering.sh
# Env overrides:
#   IMAGE  (default sameersbn/redmine:<VERSION from repo VERSION file>)
#   PORT   (default 10091 — smoke-compose.sh uses 10083, so these can coexist)
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO" || exit 1

IMAGE="${IMAGE:-sameersbn/redmine:$(cat VERSION)}"
PORT="${PORT:-10091}"
BASE="http://localhost:${PORT}"
CONTAINER="repro-theme-ordering"
VOL="repro-theme-ordering-data"
MANIFEST=/home/redmine/redmine/public/assets/.manifest.json
# Logical manifest path of the custom theme's compiled stylesheet. Redmine gives
# an external theme the asset prefix "themes/<name>/", so its application.css is
# keyed under "themes/reprotheme/application.css" when the theme is compiled in.
THEME_MATCH='themes/reprotheme/application'

cleanup() {
  docker rm -f "$CONTAINER" >/dev/null 2>&1
  docker volume rm -f "$VOL" >/dev/null 2>&1
}
trap cleanup EXIT

fail() { echo "FAIL: $1"; exit 1; }

# Recreate the container from the image against the (persistent) data volume.
# `docker rm -f` + `docker run` gives a fresh container filesystem — equivalent
# to `docker compose up -d --force-recreate` — which is what a real deploy does.
recreate_container() {
  docker rm -f "$CONTAINER" >/dev/null 2>&1
  docker run -d --name "$CONTAINER" -p "${PORT}:80" \
    -e DB_ADAPTER=sqlite3 -e DB_NAME=db.sqlite3 \
    -e REDMINE_PORT="${PORT}" -e REDMINE_HTTPS=false -e REDMINE_RELATIVE_URL_ROOT= \
    -e SMTP_ENABLED=false -e IMAP_ENABLED=false \
    -v "${VOL}:/home/redmine/data" \
    "$IMAGE" >/dev/null
}

waitup() {
  local code i
  for i in $(seq 1 120); do
    code=$(curl -s -o /dev/null -w '%{http_code}' -m 5 "$BASE/up" 2>/dev/null || echo 000)
    [ "$code" = "200" ] && return 0
    sleep 3
  done
  return 1
}

# Non-zero count => the custom theme's stylesheet is compiled into the manifest.
theme_in_manifest() {
  docker exec "$CONTAINER" grep -c "$THEME_MATCH" "$MANIFEST" 2>/dev/null
}

echo ">>> theme-recompile ordering regression test (image ${IMAGE})"

# Fresh volume seeded with a minimal valid custom theme + plugin.
cleanup
docker volume create "$VOL" >/dev/null || fail "could not create volume"
docker run --rm -v "${VOL}:/data" busybox sh -c '
  set -e
  mkdir -p /data/themes/reprotheme/stylesheets /data/plugins/repro_plugin
  printf "/* reprotheme v1 */\nbody { background: #eef; }\n" \
    > /data/themes/reprotheme/stylesheets/application.css
  {
    echo "Redmine::Plugin.register :repro_plugin do"
    echo "  name \"Repro Plugin\""
    echo "  version \"0.0.1\""
    echo "end"
  } > /data/plugins/repro_plugin/init.rb
' || fail "could not seed volume"

echo "== Step 1: clean boot — establish the good state =="
recreate_container || fail "initial container start failed"
waitup || { docker logs "$CONTAINER" 2>&1 | tail -20; fail "/up never returned 200 on clean boot"; }
[ "$(theme_in_manifest)" -gt 0 ] 2>/dev/null \
  || fail "baseline broken: custom theme not in manifest after clean boot"
echo "   OK: custom theme present in manifest after clean boot"

echo "== Step 2: change ONLY the plugin, recreate a fresh container =="
# Bump only the plugin's content; the theme content stays byte-for-byte
# identical so its sha1 is unchanged.
docker run --rm -v "${VOL}:/data" busybox sh -c \
  'echo "# bump $(cat /proc/sys/kernel/random/uuid 2>/dev/null || date +%s)" >> /data/plugins/repro_plugin/init.rb' \
  || fail "could not bump plugin"
recreate_container || fail "force-recreate failed"
waitup || { docker logs "$CONTAINER" 2>&1 | tail -20; fail "/up never returned 200 after recreate"; }

if [ "$(theme_in_manifest)" -gt 0 ] 2>/dev/null; then
  echo "   OK: custom theme survived plugin-only recreate"
  echo "PASS: theme-recompile ordering"
  exit 0
else
  fail "custom theme MISSING from manifest after plugin-only recreate (ordering bug present)"
fi
