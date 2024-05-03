#!/bin/bash
set -e

# Tests issue https://github.com/Helioviewer-Project/helioviewer.org-docker/issues/42
# When restarting the API Server, the hgs2hpc process does not restart
# Pre-requisites
#   - Contains have already been started with `docker compose up`
# Test steps
#  1. Verify that the hgs2hpc service is running
#  2. Stop the API container
#  3. Restart the API container
#  4. Verify that the hgs2hpc service is running

# 1. Verify hgs2hpc service is running
# preg returns exit code 1 if the process is not found, which will make this
# test fail
docker exec -it helioviewer-api-1 pgrep -f hgs2hpc

# 2. Stop the API container
docker container stop helioviewer-api-1

# 3. Restart the API container and wait for it to be ready
docker compose up -d --wait

# 4. Verify that the hgs2hpc service is running
docker exec -it helioviewer-api-1 pgrep -f hgs2hpc