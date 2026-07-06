#!/bin/bash
# Helpers for talking to a running Redmine over HTTP(S) with curl.
# Source this file, then use redmine_login / redmine_get.
#
# Both take the base URL and a cookie-jar path; any extra args (e.g. -k for a
# self-signed HTTPS endpoint) are forwarded verbatim to curl.

# redmine_login <base-url> <cookie-jar> <username> <password> [curl-opts...]
# Runs Redmine's CSRF login flow: GET /login to grab the authenticity_token,
# then POST /login with the credentials, storing the session in <cookie-jar>.
# Echoes the POST's HTTP status code (302 on success).
redmine_login() {
  local base="$1" cookie="$2" user="$3" pass="$4"; shift 4
  local token
  token=$(curl -s "$@" -c "$cookie" "$base/login" \
    | grep -oE 'name="authenticity_token" value="[^"]+"' | head -1 \
    | sed -E 's/.*value="([^"]+)".*/\1/')

  curl -s "$@" -o /dev/null -w "%{http_code}" -b "$cookie" -c "$cookie" \
    --data-urlencode "authenticity_token=$token" \
    --data-urlencode "username=$user" \
    --data-urlencode "password=$pass" \
    --data-urlencode "login=Login" \
    "$base/login"
}

# redmine_get <base-url> <cookie-jar> <path> [curl-opts...]
# GET an authenticated path using the session cookie jar; writes the body to stdout.
redmine_get() {
  local base="$1" cookie="$2" path="$3"; shift 3
  curl -s "$@" -b "$cookie" "$base$path"
}
