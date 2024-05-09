#!/bin/bash

# This test verifies that there is an AIA 304 image and AIA 171 image installed in the container
# The Helioviewer API and "output=minimal" page each expect an AIA 171 to be present.
# Test Steps:
#   1. Examine the jp2 directory
#   2. Verify the AIA 304 image is present
#   3. Verify the AIA 171 image is present

exit_code=0
jp2ls=$(docker exec helioviewer-api-1 ls /tmp/jp2)
echo "ls /tmp/jp2:"
# Print out the files for debug purposes in case this test fails.
echo $jp2ls

# 1. Examine the jp2 directory for images
aia_images=$(echo $jp2ls | grep AIA)

# 2. Verify the AIA 304 image is present
img=$(echo $aia_images | grep 304)
if [ -z $img ]; then
    echo "Missing AIA 304 image"
    exit_code=1
fi

# 3. Verify the AIA 171 image is present
aia_171=$(echo $aia_images | grep 171)
if [ -z $aia_171 ]; then
    echo "Missing AIA 171 image"
    exit_code=1
fi

exit $exit_code
