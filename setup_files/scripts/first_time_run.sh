# Define the lock file
first_run=/root/setup_files/scripts/first_run.lock

# if the lock file exists, then don't do anything
if [ ! -f "$first_run" ]
then

    # First time run, copy configuration files where they should go to
    # allow helioviewer to run with "localhost" requests.

    # Bring in script variabls like API_DIR and SITE_DIR
    source vars.sh

    # Create api cache and log directories
    cd $API_DIR
    mkdir docroot/cache
    mkdir log

    # Set up site config and create local directories
    cp ~/setup_files/app_config/Config.js $SITE_DIR/resources/js/Utility/Config.js
    cp ~/setup_files/app_config/settings.cfg $API_DIR/install/settings/settings.cfg

    su www-data -s /bin/bash -c "mkdir -p $SITE_DIR/log $SITE_DIR/cache"

    # Copy API configuration files
    if [ ! -f "$API_DIR/settings/Config.ini" ]
    then
        cp ~/setup_files/app_config/Config.ini $API_DIR/settings/Config.ini
    fi

    if [ ! -f "$API_DIR/settings/Private.php" ]
    then
        cp ~/setup_files/app_config/Private.php $API_DIR/settings/Private.php
    fi

    ln -s /var/www/jp2 $API_DIR/docroot/jp2

    # Minify css/js
    cd $SITE_DIR/resources/build
    chmod +x jsmin/jsmin.py # workaround for now
    ant

    # Create lock file so this script does not do anything on future runs
    touch $first_run
fi
