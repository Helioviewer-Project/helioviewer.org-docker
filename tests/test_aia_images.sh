#!/bin/bash
set -e

# This test verifies that there is an AIA 304 image and AIA 171 image installed in the container
# The Helioviewer API and "output=minimal" page each expect an AIA 171 to be present.
# Test Steps:
#   2. Verify AIA 304 data is there
#   3. Verify AIA 171 data is there

# 2. Verify the AIA 304 image is present
echo "Checking for AIA 304 image"
TEST_DATA_DIR=/tmp/jp2/AIA/2024/12/31
docker compose exec api ls $TEST_DATA_DIR | grep 304

# 3. Verify the AIA 171 image is present
echo "Checking for AIA 171 image"
docker compose exec api ls $TEST_DATA_DIR | grep 171

