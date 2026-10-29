#!/bin/bash
# Exit on failure
set -e

# This test verifies that the php containers select the correct php.ini
# based on the ENV environment variable.
# Test Steps:
#   1. Verify the running "api" service (no ENV override) uses php.ini-production
#   2. Start a one-off "api" container with ENV=dev and verify it uses php.ini-development

# 1. Verify the default (production) php.ini is loaded by the running api service
echo "Checking default php.ini (expect production)"
prod_ini=$(docker compose exec api php --ini | grep "Loaded Configuration File")
echo "$prod_ini"
if ! echo "$prod_ini" | grep -q "/usr/local/etc/php/prod/php.ini"; then
    echo "Error: api service is not using the production php.ini by default"
    exit 1
fi

# 2. Verify ENV=dev selects the development php.ini
echo "Checking php.ini with ENV=dev (expect development)"
dev_ini=$(docker compose run --rm -e ENV=dev api php --ini | grep "Loaded Configuration File")
echo "$dev_ini"
if ! echo "$dev_ini" | grep -q "/usr/local/etc/php/dev/php.ini"; then
    echo "Error: ENV=dev did not select the development php.ini"
    exit 1
fi

echo "php.ini selection works correctly for both production and dev"
