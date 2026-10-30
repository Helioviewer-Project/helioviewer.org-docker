#!/bin/bash
# Exit on failure
set -e

# This test verifies that docker/php.Dockerfile's CMD matches the CMD of the
# upstream base image it builds from.
#
# Setting ENTRYPOINT in a derived Dockerfile resets any CMD inherited from
# the base image to empty (a documented Docker gotcha), so php.Dockerfile
# must redeclare CMD explicitly to match the base image's default command.
# If the base image is ever bumped to a version with a different CMD, this
# test should fail so the redeclared CMD gets updated to match.
#
# Test Steps:
#   1. Extract the base image ref (FROM line) from docker/php.Dockerfile
#   2. Extract our own CMD (last CMD line) from docker/php.Dockerfile
#   3. Pull the base image and inspect its default CMD
#   4. Compare the two

DOCKERFILE=../docker/php.Dockerfile

# 1. Extract the base image ref
base_image=$(grep -m1 "^FROM " "$DOCKERFILE" | awk '{print $2}')
echo "Base image: $base_image"

# 2. Extract our CMD
our_cmd=$(grep "^CMD " "$DOCKERFILE" | tail -n1 | sed 's/^CMD //')
echo "Our CMD: $our_cmd"

# 3. Pull the base image and inspect its CMD
docker pull "$base_image" >/dev/null
upstream_cmd=$(docker inspect "$base_image" --format '{{json .Config.Cmd}}')
echo "Upstream CMD: $upstream_cmd"

# 4. Compare the two (normalize JSON formatting before comparing)
our_cmd_normalized=$(echo "$our_cmd" | jq -c .)
upstream_cmd_normalized=$(echo "$upstream_cmd" | jq -c .)

if [ "$our_cmd_normalized" != "$upstream_cmd_normalized" ]; then
    echo "Error: CMD in $DOCKERFILE ($our_cmd_normalized) does not match upstream image $base_image's CMD ($upstream_cmd_normalized)"
    echo "Update the CMD in $DOCKERFILE to match the upstream image."
    exit 1
fi

echo "CMD in $DOCKERFILE matches upstream image $base_image"
