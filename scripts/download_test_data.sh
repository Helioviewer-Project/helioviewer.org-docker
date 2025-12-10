#!/bin/bash

# This test verifies that downloaders are working as expected
# Test Steps:
#   1. Run each downloader on a small period of time
#   2. Verify that downloader completes successfully

declare -A start_date
declare -A end_date
declare -A hv_url

# IRIS jpeg2000s are not publicly retrievable and cannot be tested here.
# kcor is not active and has a bug at the time of writing where XML can't be parsed.
downloaders=(kcor halpha aia hmi rob xrt hv_soho hv_stereo suvi solar_orbiter hv_rhessi)

# Helioviewer.org JP2 URL lookup table
hv_url["kcor"]="https://helioviewer.org/jp2/KCor"
hv_url["halpha"]="https://helioviewer.org/jp2/NSO-GONG"
hv_url["aia"]="https://helioviewer.org/jp2/AIA"
hv_url["hmi"]="https://helioviewer.org/jp2/HMI"
hv_url["rob"]="https://helioviewer.org/jp2/SWAP"
hv_url["xrt"]="https://helioviewer.org/jp2/XRT"
hv_url["suvi"]="https://helioviewer.org/jp2/SUVI"
hv_url["solar_orbiter"]="https://helioviewer.org/jp2/FSI"

# optional date ranges.
# default is 3 months ago
default_start="2024-12-31 00:00:00"
default_end="2024-12-31 00:05:00"

start_date["xrt"]="2024-11-07 00:00:00"
end_date["xrt"]="2024-11-07 01:00:00"

start_date["hv_soho"]="2023-12-01 00:00:00"
end_date["hv_soho"]="2023-12-01 01:00:00"

start_date["hv_stereo"]="2024-10-08 01:00:00"
end_date["hv_stereo"]="2024-10-08 02:00:00"

start_date["solar_orbiter"]="2024-07-02 12:00:00"
end_date["solar_orbiter"]="2024-07-02 12:10:00"

start_date["hv_rhessi"]="2018-02-11 00:00:00"
end_date["hv_rhessi"]="2018-02-11 5:00:00"

start_date["kcor"]="2024-04-09 17:48:00"
end_date["kcor"]="2024-04-09 17:50:00"

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

    # Check if downloader has an HV URL defined
    if [ -n "${hv_url["$downloader"]}" ]; then
        # Use the hv downloader with HV_DATA_PATH environment variable
        HV_DATA_PATH="${hv_url["$downloader"]}" /app/downloader.expect hv "$query_start" "$query_end"
    else
        # Use the downloader directly
        /app/downloader.expect $downloader "$query_start" "$query_end"
    fi
done
