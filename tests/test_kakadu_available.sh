#!/bin/bash
# Exit on failure
set -e

# This test verifies that the Kakadu kdu_* commands are installed and
# available on the PATH inside the php image.

IMAGE="${1:-ghcr.io/helioviewer-project/php}"

for cmd in kdu_compress kdu_expand; do
    echo "Checking that $cmd is available in the $IMAGE image"
    if ! docker run --rm "$IMAGE" which "$cmd" >/dev/null; then
        echo "Error: $cmd is not available in the $IMAGE image"
        exit 1
    fi
done

echo "Kakadu kdu_* commands are available in the $IMAGE image"
