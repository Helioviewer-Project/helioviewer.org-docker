#!/bin/bash

# Helioviewer.org Docker Management Script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Show usage information
usage() {
    echo "Usage: $0 <command>"
    echo ""
    echo "Available commands:"
    echo "  init          Initialize settings for Docker environment"
    echo "  composer      Run composer commands in the API container"
    echo "  downloader    Run the Helioviewer data downloader"
    echo ""
}

# Load environment variables from .env file
load_env() {
    local env_file="${SCRIPT_DIR}/.env"

    if [ ! -f "${env_file}" ]; then
        echo "Error: ${env_file} not found"
        exit 1
    fi

    source "${env_file}"
}

# Check if file should be overwritten
# Returns 0 (true) if file should be overwritten, 1 (false) otherwise
# Returns 0 (true) if the file doesn't exist.
should_overwrite() {
    local fname="$1"

    if [ ! -f "${fname}" ]; then
        return 0
    fi

    echo "Warning: ${fname} already exists"
    read -p "Overwrite existing $(basename "${fname}")? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Initialize settings.cfg for Docker environment
init_settings() {
    echo "Initializing settings.cfg for Docker environment..."

    local settings_example="${SCRIPT_DIR}/api/install/settings/settings.example.cfg"
    local settings_file="${SCRIPT_DIR}/api/install/settings/settings.cfg"

    if [ ! -f "${settings_example}" ]; then
        echo "Error: ${settings_example} not found"
        exit 1
    fi

    if should_overwrite "${settings_file}"; then
        # Load environment variables from .env file
        load_env

        # Copy example file
        cp "${settings_example}" "${settings_file}"

        # Replace localhost with Docker service names
        sed -i.bak 's/^dbhost = localhost$/dbhost = database/' "${settings_file}"
        # Replace database configuration with environment variables
        sed -i.bak "s/^dbname = helioviewer$/dbname = ${HV_DB_NAME}/" "${settings_file}"
        sed -i.bak "s/^dbuser = helioviewer$/dbuser = ${HV_DB_USER}/" "${settings_file}"
        sed -i.bak "s/^dbpass = helioviewer$/dbpass = ${HV_DB_PASS}/" "${settings_file}"
        # Replace /mnt/data paths with /tmp paths for Docker volumes
        sed -i.bak 's|/mnt/data/hvpull|/tmp/hvpull|g' "${settings_file}"
        sed -i.bak 's|/mnt/data/jp2|/tmp/jp2|g' "${settings_file}"
        # Clean up backup file
        rm -f "${settings_file}.bak"

        echo "Settings initialized successfully at ${settings_file}"
    else
        echo "Skipping settings.cfg initialization"
    fi
}

# Initialize Config.ini and Private.php for Docker environment
init_config() {
    echo "Initializing Config.ini for Docker environment..."

    local config_example="${SCRIPT_DIR}/api/settings/Config.Example.ini"
    local config_file="${SCRIPT_DIR}/api/settings/Config.ini"

    if [ ! -f "${config_example}" ]; then
        echo "Error: ${config_example} not found"
        exit 1
    fi

    if should_overwrite "${config_file}"; then
        # Load environment variables from .env file
        load_env

        # Copy example file
        cp "${config_example}" "${config_file}"

        # Replace paths and URLs with Docker-appropriate values
        sed -i.bak 's|jp2_dir      = /var/www-api/docroot/jp2|jp2_dir      = /tmp/jp2|' "${config_file}"
        sed -i.bak "s|web_root_url     = http://localhost|web_root_url     = http://${API_URL}|" "${config_file}"
        sed -i.bak "s|client_url       = http://helioviewer.org|client_url       = http://${CLIENT_URL}|" "${config_file}"
        sed -i.bak "s|coordinator_url = 'http://coordinator'|coordinator_url = 'http://${COORDINATOR_URL}'|" "${config_file}"
        sed -i.bak 's|/var/www-api/docroot|/var/www/api.helioviewer.org/docroot|g' "${config_file}"

        # Clean up backup file
        rm -f "${config_file}.bak"

        echo "Config.ini initialized successfully at ${config_file}"
    else
        echo "Skipping Config.ini initialization"
    fi

    # Initialize Private.php
    echo "Initializing Private.php..."
    local private_example="${SCRIPT_DIR}/api/settings/Private.Example.php"
    local private_file="${SCRIPT_DIR}/api/settings/Private.php"

    if [ ! -f "${private_example}" ]; then
        echo "Error: ${private_example} not found"
        exit 1
    fi

    if should_overwrite "${private_file}"; then
        cp "${private_example}" "${private_file}"
        echo "Private.php initialized successfully at ${private_file}"
    else
        echo "Skipping Private.php initialization"
    fi
}

# Install PHP dependencies via Composer
init_composer() {
    echo "Installing PHP dependencies..."
    composer install
}

# Initialize all settings for Docker environment
init() {
    echo "Initializing Helioviewer settings for Docker environment..."
    echo "-------------------------------------------"

    init_settings
    echo "-------------------------------------------"

    init_config
    echo "-------------------------------------------"

    init_composer
}

# Run composer in the API container
composer() {
    docker compose exec api /usr/bin/composer "$@"
}

# Run the downloader
downloader() {
    echo "Starting Helioviewer downloader..."

    # Load environment variables from .env file
    load_env

    docker run --rm \
        --init \
        --stop-timeout 0 \
        --network helioviewer_default \
        --user "${UID}:$(id -g)" \
        --env-file "${SCRIPT_DIR}/.env" \
        --platform=linux/x86_64 \
        -e HOME=/tmp \
        -v "${SCRIPT_DIR}/api/install:/app" \
        -v "${HOST_JPEG2000_PATH}:/tmp/jp2" \
        ghcr.io/helioviewer-project/python \
        /app/downloader.py "$@"
}

# Main command dispatcher
case "$1" in
    init)
        init
        ;;
    composer)
        shift
        composer "$@"
        ;;
    downloader)
        shift
        downloader "$@"
        ;;
    *)
        echo "Error: Unknown command '$1'"
        echo ""
        usage
        exit 1
        ;;
esac
