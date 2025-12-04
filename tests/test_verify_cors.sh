#!/bin/bash
# Exit on failure
set -e

# This test verifies that acao_url is set for the container environment
# Test Steps:
#   1. Check Config.ini for acao_url = http://localhost:8080

# Check Config.ini for acao_url
if grep -q "acao_url\[\] = 'http://localhost:8080'" ../api/settings/Config.ini; then
    echo "acao_url is correctly set in Config.ini"
else
    echo "Error: acao_url is not set correctly in Config.ini"
    exit 1
fi
