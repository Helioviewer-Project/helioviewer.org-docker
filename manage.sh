#!/bin/bash

# Helioviewer.org Docker Management Script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Show usage information
usage() {
    echo "Usage: $0 <command>"
    echo ""
    echo "Available commands:"
    echo "  init          Initialize settings for Docker environment"
    echo "  downloader    Run the Helioviewer data downloader"
    echo ""
}

# Initialize settings for Docker environment
init() {
    echo "Initializing Helioviewer settings for Docker environment..."

    local settings_example="${SCRIPT_DIR}/api/install/settings/settings.example.cfg"
    local settings_file="${SCRIPT_DIR}/api/install/settings/settings.cfg"

    if [ ! -f "${settings_example}" ]; then
        echo "Error: ${settings_example} not found"
        exit 1
    fi

    if [ -f "${settings_file}" ]; then
        echo "Warning: ${settings_file} already exists"
        read -p "Overwrite existing settings.cfg? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Initialization cancelled"
            exit 0
        fi
    fi

    # Copy example file
    cp "${settings_example}" "${settings_file}"

    # Replace localhost with Docker service names
    sed -i.bak 's/^dbhost = localhost$/dbhost = database/' "${settings_file}"

    # Replace /mnt/data paths with /tmp paths for Docker volumes
    sed -i.bak 's|/mnt/data/hvpull|/tmp/hvpull|g' "${settings_file}"
    sed -i.bak 's|/mnt/data/jp2|/tmp/jp2|g' "${settings_file}"

    # Clean up backup file
    rm -f "${settings_file}.bak"

    echo "Settings initialized successfully at ${settings_file}"
    echo "Database host changed from 'localhost' to 'database'"
    echo "Working directory changed from '/mnt/data/hvpull' to '/tmp/hvpull'"
    echo "Image archive changed from '/mnt/data/jp2' to '/tmp/jp2'"
}

# Run the downloader
downloader() {
    echo "Starting Helioviewer downloader..."
    docker run --rm \
        --network helioviewer_default \
        --user "${UID}:$(id -g)" \
        --env-file "${SCRIPT_DIR}/.env" \
        --platform=linux/x86_64 \
        -e HOME=/tmp \
        -v "${SCRIPT_DIR}/api/install:/app" \
        -v "$PWD/jp2:/tmp/jp2" \
        ghcr.io/helioviewer-project/python \
        /app/downloader.py "$@"
}

# Main command dispatcher
case "$1" in
    init)
        init
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
