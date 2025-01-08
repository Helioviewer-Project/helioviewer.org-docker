#!/bin/bash
set -e

# This test verifies that downloaders are working as expected
# Test Steps:
#   1. Run each downloader on a small period of time
#   2. Verify that downloader completes successfully

declare -A start_date
declare -A end_date

# IRIS jpeg2000s are not publicly retrievable and cannot be tested here.
# kcor is not active and has a bug at the time of writing where XML can't be parsed.
n_downloaders=9
downloaders=(halpha lmsal rob xrt hv_soho hv_stereo suvi solar_orbiter)

# optional date ranges.
# default is 3 months ago
default_start=$(date -d "3 months ago")
default_end=$(date -d "$default_start + 5 minutes")
start_date["lmsal"]="2024-12-31 00:00:00"
end_date["lmsal"]="2024-12-31 00:05:00"
start_date["hv_soho"]="2024-10-08 00:00:00"
end_date["hv_soho"]="2024-10-08 02:00:00"
start_date["hv_stereo"]="2024-10-08 00:00:00"
end_date["hv_stereo"]="2024-10-08 02:00:00"
start_date["solar_orbiter"]="2024-07-02 12:00:00"
end_date["solar_orbiter"]="2024-07-02 12:10:00"

for downloader in ${downloaders[@]}; do
    echo "Testing $downloader downloader"
    # If there's not a date in the list, then use the default dates
    if [ -z "${start_date["$downloader"]}" ]; then
        query_start=$(date -d "$default_start" +"%Y-%m-%d %H:%M:%S")
        query_end=$(date -d "$default_end" +"%Y-%m-%d %H:%M:%S")
    # Otherwise use the date from the list
    else
        query_start=${start_date["$downloader"]}
        query_end=${end_date["$downloader"]}
    fi
    ./downloader.expect $downloader "$query_start" "$query_end"
done
