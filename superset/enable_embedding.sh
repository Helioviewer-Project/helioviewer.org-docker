#!/bin/bash
set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 superset_url session csrf_token"
    echo
    echo "  You can get these by analyzing the network tab in a logged in session"
    exit
fi

SUPERSET_URL=$1
SESSION=$2
CSRFTOKEN=$3

# Execute a curl request with the session specified from CLI args
_curl() {
    curl "$@" \
    -H "Cookie: $SESSION" \
    -H "X-CSRFToken: $CSRFTOKEN"
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

# Reads a list of dashboard IDs from stdin and enables embedding on it.
# each dashboard ID should be on a new line
# This processes the output from ids_from_curl_response
enable_embeddings() {
  PAGE=$1
  if [ -z $PAGE ]; then echo "Invalid page passed to enable_embedding"; exit; fi;
  n=0
  while read id; do
    echo "Enabling embedding for Dashboard ID $id"
    _curl -X POST -s "$SUPERSET_URL/api/v1/dashboard/$id/embedded" -H 'Content-Type: application/json' -d '{"allowed_domains":[]}'
    n=1
  done
  if [ $n -eq 0 ]; then exit; fi;
  enable_all_embeddings $(($PAGE+1))
}

# Enables all embeddings on all Ingestion dashboards
enable_all_embeddings() {
    PAGE=$1
    get_dashboard_ids $1 | enable_embeddings $1
}

enable_all_embeddings 0
