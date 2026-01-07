#!/bin/bash

# Helioviewer.org Docker Management Script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Show usage information
usage() {
    echo "Usage: $0 <command>"
    echo ""
    echo "Available commands:"
    echo "  init               Initialize settings for Docker environment"
    echo "  init_everything    Run init, npm_install, build_js_css, and create data directories"
    echo "  composer           Run composer commands in the API container"
    echo "  npm_install        Install npm dependencies for web client"
    echo "  build_js_css       Build JavaScript and CSS for web client"
    echo "  watch_js           Watch and rebuild JavaScript on changes"
    echo "  watch_3d           Watch and rebuild 3D JavaScript on changes"
    echo "  downloader         Run the Helioviewer data downloader"
    echo "  download_test_data Download test data for development"
    echo "  pytest             Run pytest tests in the Python container"
    echo "  init_superset      Initialize Superset database and default roles/permissions"
    echo "  prepare-dashboard  Prepare a dashboard export zip file for import"
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
        # Disable email notifications by setting server to empty string
        sed -i.bak 's/^server = localhost$/server = /' "${settings_file}"
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
        sed -i.bak "s|web_root_url     = http://localhost|web_root_url     = ${API_URL}|" "${config_file}"
        sed -i.bak "s|client_url       = http://helioviewer.org|client_url       = ${CLIENT_URL}|" "${config_file}"
        sed -i.bak "s|coordinator_url = 'http://coordinator'|coordinator_url = 'http://coordinator'|" "${config_file}"
        sed -i.bak 's|/var/www-api/docroot|/var/www/api.helioviewer.org/docroot|g' "${config_file}"

        # Add CORS allowed origins
        sed -i.bak "s|;acao_url\[\] = ''|acao_url[] = 'http://localhost:8080'\nacao_url[] = 'http://127.0.0.1:8080'\nacao_url[] = '${CLIENT_URL}'|" "${config_file}"

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

# Initialize web client Config.js for Docker environment
init_web_config() {
    echo "Initializing web client Config.js for Docker environment..."

    local config_file="${SCRIPT_DIR}/helioviewer.org/resources/js/Utility/Config.js"

    if [ ! -f "${config_file}" ]; then
        echo "Error: ${config_file} not found"
        exit 1
    fi

    # Load environment variables from .env file
    load_env

    # Replace API and client URLs with Docker-appropriate values
    sed -i.bak "s|'back_end'                  : \"https://api.helioviewer.org/\"|'back_end'                  : \"${API_URL}/\"|" "${config_file}"
    sed -i.bak "s|'web_root_url'              : \"https://helioviewer.org\"|'web_root_url'              : \"${CLIENT_URL}\"|" "${config_file}"
    sed -i.bak "s|'user_video_feed'           : \"https://api.helioviewer.org/\"|'user_video_feed'           : \"${API_URL}/\"|" "${config_file}"
    sed -i.bak "s|'coordinator_url'           : 'https://api.helioviewer.org/coordinate'|'coordinator_url'           : '${COORDINATOR_URL}'|" "${config_file}"

    # Clean up backup file
    rm -f "${config_file}.bak"

    echo "Web client Config.js initialized successfully at ${config_file}"
}

# Install PHP dependencies via Composer
init_composer() {
    echo "Installing PHP dependencies..."
    docker run --rm \
        --user "${UID}:$(id -g)" \
        -v "${SCRIPT_DIR}/api:/app" \
        -w /app \
        composer:latest \
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

    init_web_config
    echo "-------------------------------------------"

    init_composer

    # Files required for API tests
    load_env
    cp compose/*.jp2 $HOST_JPEG2000_PATH
}

# Initialize everything: run init, npm_install, build_js_css, and create data directories
init_everything() {
    echo "Running full initialization..."
    echo "-------------------------------------------"

    # Load environment variables
    load_env

    # Create necessary data directories
    echo "Creating data directories..."
    mkdir -p "${HOST_JPEG2000_PATH}" "${HOST_CACHE_PATH}" "${HOST_LOG_PATH}"
    echo "Data directories created: ${HOST_JPEG2000_PATH}, ${HOST_CACHE_PATH}, ${HOST_LOG_PATH}"
    echo "-------------------------------------------"

    # Run init
    init
    echo "-------------------------------------------"

    # Install npm dependencies
    npm_install
    echo "-------------------------------------------"

    # Build JavaScript and CSS
    build_js_css
    echo "-------------------------------------------"

    # Initialize Superset
    init_superset

    echo "-------------------------------------------"
    echo "Full initialization completed successfully!"
}

# Run composer in the API container
composer() {
    docker compose exec api /usr/bin/composer "$@"
}

# Install npm dependencies for web client
npm_install() {
    echo "Installing npm dependencies..."
    docker run --rm \
        --user "${UID}:$(id -g)" \
        -e HOME=/tmp \
        -e NODE_OPTIONS='--localstorage-file=/tmp/helioviewer_localstorage' \
        -e npm_config_cache=/tmp/.npm \
        -v "${SCRIPT_DIR}/helioviewer.org:/app" \
        -w /app \
        node:lts \
        npm ci
}

# Build JavaScript and CSS for web client
build_js_css() {
    echo "Building JavaScript and CSS..."
    docker run --rm \
        --user "${UID}:$(id -g)" \
        -e HOME=/tmp \
        -v "${SCRIPT_DIR}/helioviewer.org:/app/helioviewer.org" \
        -w /app/helioviewer.org/resources/build \
        ghcr.io/helioviewer-project/node \
        ant
}

# Watch and rebuild JavaScript on changes
watch_js() {
    echo "Watching JavaScript for changes..."
    cd "${SCRIPT_DIR}/helioviewer.org/resources/build" && npx webpack watch
}

# Watch and rebuild 3D JavaScript on changes
watch_3d() {
    echo "Watching 3D JavaScript for changes..."
    cd "${SCRIPT_DIR}/helioviewer.org/resources/build" && npx webpack --config webpack3d.config.js watch
}

# Run the downloader
downloader() {
    echo "Starting Helioviewer downloader..."

    # Load environment variables from .env file
    load_env

    # Run in detached mode and trap SIGINT to send SIGKILL for immediate stop
    local container_id
    container_id=$(docker run -d \
        --init \
        --stop-timeout 0 \
        --network helioviewer_default \
        --user "${UID}:$(id -g)" \
        --env-file "${SCRIPT_DIR}/.env" \
        --platform=linux/x86_64 \
        -e HOME=/tmp \
        -e HV_DATA_PATH="${HV_DATA_PATH}" \
        -v "${SCRIPT_DIR}/api/install:/app" \
        -v "${HOST_JPEG2000_PATH}:/tmp/jp2" \
        ghcr.io/helioviewer-project/python \
        /app/downloader.py "$@")

    # Trap Ctrl+C to kill container immediately
    trap "docker kill ${container_id} 2>/dev/null; exit 0" SIGINT SIGTERM

    # Follow logs and wait for container to finish
    docker logs -f "${container_id}"
    docker wait "${container_id}" >/dev/null 2>&1
}

# Download test data
download_test_data() {
    echo "Downloading test data..."

    # Load environment variables from .env file
    load_env

    # Create push directory if it doesn't exist
    mkdir -p "${HOST_JPEG2000_PATH}/push"

    # Download and extract the test data tarball
    echo "Downloading test data tarball from https://helioviewer.org/jp2/sample.tar.gz..."
    curl -L -o /tmp/sample.tar.gz https://helioviewer.org/jp2/sample.tar.gz

    echo "Extracting test data to ${HOST_JPEG2000_PATH}/push/..."
    tar -xzf /tmp/sample.tar.gz -C "${HOST_JPEG2000_PATH}/push/"
    rm -f /tmp/sample.tar.gz

    echo "Processing test data with downloader..."
    # Run the downloader to process the extracted files
    docker run --rm \
        --init \
        --stop-timeout 0 \
        --network helioviewer_default \
        --user "${UID}:$(id -g)" \
        --env-file "${SCRIPT_DIR}/.env" \
        --platform=linux/x86_64 \
        --entrypoint /bin/sh \
        -e HOME=/tmp \
        -e HV_DATA_PATH="${HV_DATA_PATH}" \
        -v "${SCRIPT_DIR}/api/install:/app" \
        -v "${HOST_JPEG2000_PATH}:/tmp/jp2" \
        ghcr.io/helioviewer-project/python \
        -c 'expect -c "
          set timeout -1
          spawn python3 /app/downloader.py -d local -b local -m localmove -s \"1900-01-01 00:00:00\" -e \"2100-01-01 00:00:00\"
          expect \"Sleeping for 30 minutes\"
          exit 0
        "'

    echo "Test data downloaded and processed successfully"
}

# Run pytest tests
pytest() {
    echo "Running pytest tests..."
    load_env

    docker run --rm \
        --user "${UID}:$(id -g)" \
        --network helioviewer_default \
        -e HOME=/tmp \
        -e PYTEST_API_HOST=api \
        -v "${SCRIPT_DIR}/api:/app" \
        -v "${HOST_JPEG2000_PATH}:/tmp/jp2" \
        -w /app/install \
        ghcr.io/helioviewer-project/python \
        -m pytest
}

# Initialize Superset
init_superset() {
    echo "Initializing Superset database and default roles/permissions..."
    load_env

    docker compose exec superset superset db upgrade && \
    docker compose exec superset superset init && \
    docker compose exec superset superset fab create-admin \
        --username "${SUPERSET_ADMIN_USER}" \
        --firstname Admin \
        --lastname User \
        --email admin@localhost \
        --password "${SUPERSET_ADMIN_PASS}" && \
    docker compose cp superset/dashboards_prepared.zip superset:/tmp/dashboards.zip && \
    docker compose exec superset superset import-dashboards -p /tmp/dashboards.zip -u admin
}

# Prepare dashboard export zip file for import
prepare_dashboard() {
    local zip_file="$1"

    if [ -z "${zip_file}" ]; then
        echo "Error: No zip file specified"
        echo "Usage: $0 prepare-dashboard <path-to-dashboard.zip>"
        exit 1
    fi

    if [ ! -f "${zip_file}" ]; then
        echo "Error: File '${zip_file}' not found"
        exit 1
    fi

    echo "Preparing dashboard export from ${zip_file}..."
    load_env

    # Create temporary directory
    local temp_dir=$(mktemp -d)
    echo "Using temporary directory: ${temp_dir}"

    # Unzip the file
    echo "Extracting dashboard export..."
    unzip -q "${zip_file}" -d "${temp_dir}"

    # Find and edit the databases YAML file
    local db_yaml="${temp_dir}/dashboard_export_"*"/databases/Helioviewer_Daily.yaml"
    if [ -f ${db_yaml} ]; then
        echo "Updating database configuration in ${db_yaml}..."
        sed -i.bak "s|^sqlalchemy_uri:.*|sqlalchemy_uri: mysql://${SUPERSET_READ_USER}:${SUPERSET_READ_PASS}@${HV_DB_HOST}:3306/${HV_DB_NAME}|" ${db_yaml}
        rm -f "${db_yaml}.bak"
    else
        echo "Warning: Database YAML file not found at expected path"
    fi

    # Find and edit the datasets data.yaml file
    local dataset_yaml="${temp_dir}/dashboard_export_"*"/datasets/Helioviewer_Daily/data.yaml"
    if [ -f ${dataset_yaml} ]; then
        echo "Updating dataset schema in ${dataset_yaml}..."
        sed -i.bak "s|^schema: helioviewer|schema: ${HV_DB_NAME}|" ${dataset_yaml}
        rm -f "${dataset_yaml}.bak"
    else
        echo "Warning: Dataset YAML file not found at expected path"
    fi

    # Create output zip file
    local output_file="${SCRIPT_DIR}/superset/dashboards_prepared.zip"
    echo "Creating prepared dashboard export at ${output_file}..."
    cd "${temp_dir}" && zip -q -r "${output_file}" .

    # Clean up temporary directory
    echo "Cleaning up temporary directory..."
    rm -rf "${temp_dir}"

    echo "Dashboard export prepared successfully at ${output_file}"
    echo "You can now import this file into Superset"
}

# Main command dispatcher
case "$1" in
    init)
        init
        ;;
    init_everything)
        init_everything
        ;;
    composer)
        shift
        composer "$@"
        ;;
    npm_install)
        npm_install
        ;;
    build_js_css)
        build_js_css
        ;;
    watch_js)
        watch_js
        ;;
    watch_3d)
        watch_3d
        ;;
    downloader)
        shift
        downloader "$@"
        ;;
    download_test_data)
        download_test_data
        ;;
    pytest)
        shift
        pytest "$@"
        ;;
    init_superset)
        init_superset
        ;;
    prepare-dashboard)
        shift
        prepare_dashboard "$@"
        ;;
    *)
        echo "Error: Unknown command '$1'"
        echo ""
        usage
        exit 1
        ;;
esac
