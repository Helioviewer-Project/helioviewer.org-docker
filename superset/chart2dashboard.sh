#!/bin/bash

# Script to create a dashboard for every chart in Superset
# Usage: ./chart2dashboard.sh <superset-base-url> <username> [-c <cookie>]
# Usage with cookie: ./chart2dashboard.sh <superset-base-url> - -c "session=xyz"

set -e
set -o pipefail
set -x

# Parse arguments
SUPERSET_URL=""
USERNAME=""
COOKIE=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        -c)
            COOKIE="$2"
            shift 2
            ;;
        *)
            if [ -z "$SUPERSET_URL" ]; then
                SUPERSET_URL="$1"
            elif [ -z "$USERNAME" ]; then
                USERNAME="$1"
            else
                echo "Unknown argument: $1"
                exit 1
            fi
            shift
            ;;
    esac
done

# Check required arguments
if [ -z "$SUPERSET_URL" ] || [ -z "$USERNAME" ]; then
    echo "Usage: $0 <superset-base-url> <username> [-c <cookie>]"
    echo "Usage with cookie: $0 <superset-base-url> username -c \"session=xyz\""
    exit 1
fi

# Prompt for password
echo -n "Password: "
read -s PASSWORD
echo

# Login to Superset
echo "Logging in to Superset..."
LOGIN_RESPONSE=$(curl -sf -X POST "${SUPERSET_URL}/api/v1/security/login" \
    -H "Content-Type: application/json" \
    -d "{
        \"username\": \"${USERNAME}\",
        \"password\": \"${PASSWORD}\",
        \"provider\": \"db\",
        \"refresh\": true
    }")

# Extract access token
ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.access_token')

echo "Login successful! Access token obtained."

# Set up cookie jar
COOKIE_JAR=$(mktemp)

# If cookie is provided, add it to the cookie jar
if [ -n "$COOKIE" ]; then
    echo "Adding provided cookie to cookie jar..."
    # Parse the cookie hostname from SUPERSET_URL
    COOKIE_HOST=$(echo "$SUPERSET_URL" | sed -E 's|^https?://([^:/]+).*|\1|')
    echo "${COOKIE_HOST}	FALSE	/	FALSE	0	${COOKIE%%=*}	${COOKIE#*=}" > "$COOKIE_JAR"
fi

# Get CSRF token and save cookies
echo "Fetching CSRF token..."
CSRF_RESPONSE=$(curl -sf -X GET "${SUPERSET_URL}/api/v1/security/csrf_token/" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -b "$COOKIE_JAR" \
    -c "$COOKIE_JAR")

CSRF_TOKEN=$(echo "$CSRF_RESPONSE" | jq -r '.result')

echo "CSRF token obtained and cookies saved."

# No need for AUTH_HEADER variable - we always have ACCESS_TOKEN now

# Fetch all charts with pagination
echo "Fetching charts..."
PAGE=0
ALL_CHARTS="[]"

while true; do
    QUERY_PARAM=$(echo '{"columns":["id","slice_name"],"page":'$PAGE'}' | jq -sRr @uri)
    CHARTS_RESPONSE=$(curl -sf "${SUPERSET_URL}/api/v1/chart/?q=${QUERY_PARAM}" \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        -b "$COOKIE_JAR" \
        -H "Content-Type: application/json")

    RESULT=$(echo "$CHARTS_RESPONSE" | jq -r '.result')

    # Check if result is empty array
    if [ "$(echo "$RESULT" | jq 'length')" -eq 0 ]; then
        break
    fi

    # Append results to ALL_CHARTS
    ALL_CHARTS=$(echo "$ALL_CHARTS" | jq --argjson new "$RESULT" '. + $new')

    echo "Fetched page $PAGE with $(echo "$RESULT" | jq 'length') charts"
    PAGE=$((PAGE + 1))
done

echo "Total charts fetched: $(echo "$ALL_CHARTS" | jq 'length')"

# Create a dashboard for each chart
echo "Creating dashboards..."
echo "$ALL_CHARTS" | jq -c '.[]' | while read -r chart; do
    CHART_ID=$(echo "$chart" | jq -r '.id')
    SLICE_NAME=$(echo "$chart" | jq -r '.slice_name')

    echo "Creating dashboard for chart: $SLICE_NAME (ID: $CHART_ID)"

    # Step 1: POST to create empty dashboard
    EMPTY_DASHBOARD_JSON=$(cat <<EOF
{
    "certified_by": "",
    "certification_details": "",
    "css": "",
    "dashboard_title": "$SLICE_NAME",
    "slug": null,
    "owners": [1],
    "roles": []
}
EOF
)

    POST_RESPONSE=$(curl -sf -X POST "${SUPERSET_URL}/api/v1/dashboard/" \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        -H "Content-Type: application/json" \
        -H "X-CSRFToken: ${CSRF_TOKEN}" \
        -b "$COOKIE_JAR" \
        -d "$EMPTY_DASHBOARD_JSON")

    if [ $? -ne 0 ]; then
        echo "Failed to create dashboard for: $SLICE_NAME (ID: $CHART_ID)"
        echo "POST Response: $POST_RESPONSE"
        exit 1
    fi

    # Extract the new dashboard ID
    DASHBOARD_ID=$(echo "$POST_RESPONSE" | jq -r '.id')
    echo "Created dashboard ID: $DASHBOARD_ID"

    # Step 2: PUT to add the chart to the dashboard
    DASHBOARD_WITH_CHART=$(cat <<EOF
{
    "certified_by": "",
    "certification_details": "",
    "css": "",
    "dashboard_title": "$SLICE_NAME",
    "slug": null,
    "owners": [1],
    "roles": [],
    "json_metadata": "{\"chart_configuration\":{},\"global_chart_configuration\":{\"scope\":{\"rootPath\":[\"ROOT_ID\"],\"excluded\":[]},\"chartsInScope\":[$CHART_ID]},\"map_label_colors\":{},\"color_scheme\":\"\",\"positions\":{\"DASHBOARD_VERSION_KEY\":\"v2\",\"ROOT_ID\":{\"type\":\"ROOT\",\"id\":\"ROOT_ID\",\"children\":[\"GRID_ID\"]},\"GRID_ID\":{\"type\":\"GRID\",\"id\":\"GRID_ID\",\"children\":[\"ROW-P6zAlZ1lrKRQkOHZ1ddpv\"],\"parents\":[\"ROOT_ID\"]},\"HEADER_ID\":{\"id\":\"HEADER_ID\",\"type\":\"HEADER\",\"meta\":{\"text\":\"$SLICE_NAME\"}},\"CHART-VHbBamt_J5sD7CcP7otUu\":{\"type\":\"CHART\",\"id\":\"CHART-VHbBamt_J5sD7CcP7otUu\",\"children\":[],\"parents\":[\"ROOT_ID\",\"GRID_ID\",\"ROW-P6zAlZ1lrKRQkOHZ1ddpv\"],\"meta\":{\"width\":12,\"height\":76,\"chartId\":$CHART_ID,\"sliceName\":\"$SLICE_NAME\"}},\"ROW-P6zAlZ1lrKRQkOHZ1ddpv\":{\"type\":\"ROW\",\"id\":\"ROW-P6zAlZ1lrKRQkOHZ1ddpv\",\"children\":[\"CHART-VHbBamt_J5sD7CcP7otUu\"],\"parents\":[\"ROOT_ID\",\"GRID_ID\"],\"meta\":{\"background\":\"BACKGROUND_TRANSPARENT\"}}},\"refresh_frequency\":0,\"color_scheme_domain\":[],\"expanded_slices\":{},\"label_colors\":{},\"shared_label_colors\":[],\"timed_refresh_immune_slices\":[],\"cross_filters_enabled\":true,\"default_filters\":\"{}\",\"filter_scopes\":{}}"
}
EOF
)

    PUT_RESPONSE=$(curl -sf -X PUT "${SUPERSET_URL}/api/v1/dashboard/${DASHBOARD_ID}" \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        -H "Content-Type: application/json" \
        -H "X-CSRFToken: ${CSRF_TOKEN}" \
        -H "Referer: ${SUPERSET_URL}/superset/dashboard/${DASHBOARD_ID}/" \
        -b "$COOKIE_JAR" \
        -d "$DASHBOARD_WITH_CHART")

    if [ $? -ne 0 ]; then
        echo "Failed to update dashboard $DASHBOARD_ID for: $SLICE_NAME (ID: $CHART_ID)"
        echo "PUT Response: $PUT_RESPONSE"
        exit 1
    fi

    echo "Dashboard created and updated successfully for: $SLICE_NAME"
done

echo "All dashboards created successfully!"
