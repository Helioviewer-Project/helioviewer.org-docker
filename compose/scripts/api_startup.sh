#!/bin/bash
set -e

mkdir -p /var/www/helioviewer.org/cache/tiles
chmod 777 /var/www/helioviewer.org/cache/tiles

COMPOSER_HOME=/root composer install
/var/www/api.helioviewer.org/vendor/bin/start_hgs2hpc

pushd /var/www/api.helioviewer.org/install
python3 -m venv venv
venv/bin/python -m pip install -r test_requirements.txt
popd

bash /root/api_config.sh

chmod 777 /var/www/api.helioviewer.org/log

source /etc/apache2/envvars
/usr/sbin/apache2 -DFOREGROUND
