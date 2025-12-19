#!/bin/bash
set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 superset_url username [envfile]"
    echo
    echo "  You can get these by analyzing the network tab in a logged in session"
    exit
fi

SUPERSET_URL=$1
USERNAME=$2
ENVFILE="${3:-/dev/stdout}"
COOKIE_FILE=./cookies.tmp
UUIDS=()

echo -n "Enter Password for $USERNAME: "
read -s PASSWORD

# get_guest_token() {
#     curl -s "$GUEST_TOKEN_URL" -X POST | jq -r ".token"
# }
# GUESTTOKEN=$(get_guest_token)
# login() {
#     curl -s "$SUPERSET_URL/api/v1/security/login" -X POST -H "Content-Type: application/json" -d '{"password":"'$PASSWORD'","username":"'$USERNAME'","provider":"db","refresh":true}'
# }
# TOKEN=$(login | jq -r ".access_token")
#
# get_csrf() {
#     curl -s "$SUPERSET_URL/api/v1/security/csrf_token/" -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN"
# }
get_csrf() {
    curl -s "$SUPERSET_URL/api/v1/security/csrf_token/" -b "$COOKIE_FILE"
}
session_login() {
    rm -f "$COOKIE_FILE"
    CSRF=$(curl -s -c "$COOKIE_FILE" "$SUPERSET_URL/login/" | grep "csrf_token" | awk -F'"' '{print $8}')
    curl -s -b "$COOKIE_FILE" -c "$COOKIE_FILE" \
      -X POST \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "username=${USERNAME}&password=${PASSWORD}&csrf_token=${CSRF}" \
      "$SUPERSET_URL/login/" > /dev/null
}
session_login
CSRFTOKEN=$(get_csrf | jq -r ".result")

# Execute a curl request with the session specified from CLI args
_curl() {
    curl "$@" \
      -b "$COOKIE_FILE" \
      -H "X-CSRFToken: ${CSRFTOKEN}"
}

# Extracts the Dashboard IDs from the get_dashboard_ids response from superset.
# The output is a list of dashboard ids each on a new line.
ids_from_curl_response() {
    jq -c ".result | map(.id) | .[]"
}

# Queries superset for Dashboard IDs
get_dashboard_ids() {
  PAGE=$1
  if [ -z $PAGE ]; then PAGE=0; fi

  _curl -s -G "$SUPERSET_URL/api/v1/dashboard/" \
    --data-urlencode "q={\"page\":$PAGE,\"columns\":[\"id\"],\"filters\":[{\"col\":\"dashboard_title\",\"opr\":\"title_or_slug\",\"value\":\"Ingestion\"}]}" \
  | ids_from_curl_response
}

enable_dashboard() {
    ID=$1
    uuid=$(_curl -X POST -s "$SUPERSET_URL/api/v1/dashboard/$ID/embedded" -H 'Content-Type: application/json' -d '{"allowed_domains":[]}' | jq -r ".result.uuid")
    echo "Enabled dashboard $ID with UUID: $uuid" >&2
    UUIDS+=("$uuid")
    _curl -X PUT -s "$SUPERSET_URL/api/v1/dashboard/$ID" -H 'Content-Type: application/json' -d '{"published":true}' > /dev/null
}

# Reads a list of dashboard IDs from stdin and enables embedding on it.
# each dashboard ID should be on a new line
# This processes the output from ids_from_curl_response
enable_embeddings() {
  PAGE=$1
  if [ -z $PAGE ]; then echo "Invalid page passed to enable_embedding"; exit; fi;
  n=0
  while read id; do
    enable_dashboard $id
    n=1
  done < <(get_dashboard_ids $PAGE)
  if [ $n -eq 0 ]; then enable_data_coverage_dashboard; fi;
  if [ $n -eq 0 ]; then
      print_uuids >> $ENVFILE;
      exit;
  fi;
  enable_all_embeddings $(($PAGE+1))
}

# get_dashboard_ids returns all the Ingestion dashboards, we also need to enable the "Helioviewer Data Coverage" dashboard
enable_data_coverage_dashboard() {
  while read id; do
    enable_dashboard $id
  done < <(_curl -s -G "$SUPERSET_URL/api/v1/dashboard/" \
    --data-urlencode "q={\"page\":0,\"columns\":[\"id\"],\"filters\":[{\"col\":\"dashboard_title\",\"opr\":\"title_or_slug\",\"value\":\"Helioviewer Data Coverage\"}]}" \
  | ids_from_curl_response)
}

# Enables all embeddings on all Ingestion dashboards
enable_all_embeddings() {
    PAGE=$1
    enable_embeddings $1
}

print_uuids() {
    printf 'SUPERSET_GUEST_ALLOWED_DASHBOARDS='
    printf '%s\n' "${UUIDS[@]}" | jq -R . | jq -sc .
}

enable_all_embeddings 0


