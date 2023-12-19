#!/bin/bash --login
set -e
cp /run/secrets/api_config /var/www/api.helioviewer.org/settings/Config.ini
cp /run/secrets/api_private /var/www/api.helioviewer.org/settings/Private.php

export PATH=$PATH:/tmp/miniforge3/bin
READY_FILE=/tmp/container_ready
rm -f $READY_FILE

mkdir -p /var/www/helioviewer.org/cache/tiles
chmod 777 /var/www/helioviewer.org/cache/tiles

mamba activate helioviewer
/var/www/api.helioviewer.org/vendor/bin/start_hgs2hpc

pushd /var/www/api.helioviewer.org/install
pip install -r test_requirements.txt
popd

chmod 777 /var/www/api.helioviewer.org/log

source /etc/apache2/envvars
touch $READY_FILE
/usr/sbin/apache2 -DFOREGROUND
