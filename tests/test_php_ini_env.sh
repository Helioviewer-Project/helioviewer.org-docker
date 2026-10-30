#!/bin/bash
# Exit on failure
set -e

# This test verifies that the php containers select the correct php.ini
# based on the ENV environment variable.
# Test Steps:
#   1. Start a one-off "api" container with no ENV override and verify it uses php.ini-production
#   2. Start a one-off "api" container with ENV=dev and verify it uses php.ini-development
#
# Note: this uses "docker compose run" (not "exec") because the php.ini is
# selected by the entrypoint script at container start, based on the PHPRC
# env var it exports for its own process tree. "docker compose exec" attaches
# a new process to an already-running container and does not see that
# exported env, so it would not reflect the entrypoint's selection.
#
# "--no-deps" is required since the stack is already up: without it, "run"
# reconciles depends_on services too, which can waste time restarting all
# the other services

# 1. Verify the default (production) php.ini is loaded with no ENV override
echo "Checking default php.ini (expect production)"
prod_ini=$(docker compose run --rm --no-deps api php --ini | grep "Loaded Configuration File")
echo "$prod_ini"
if ! echo "$prod_ini" | grep -q "/usr/local/etc/php/prod/php.ini"; then
    echo "Error: api service is not using the production php.ini by default"
    exit 1
fi

# 2. Verify ENV=dev selects the development php.ini
echo "Checking php.ini with ENV=dev (expect development)"
dev_ini=$(docker compose run --rm --no-deps -e ENV=dev api php --ini | grep "Loaded Configuration File")
echo "$dev_ini"
if ! echo "$dev_ini" | grep -q "/usr/local/etc/php/dev/php.ini"; then
    echo "Error: ENV=dev did not select the development php.ini"
    exit 1
fi

echo "php.ini selection works correctly for both production and dev"
