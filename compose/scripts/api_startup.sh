#!/bin/bash
set -e
READY_FILE=/tmp/container_ready
rm -f $READY_FILE

chown www-data:www-data /var/www/helioviewer.org/cache
chown www-data:www-data /var/www/api.helioviewer.org/docroot/cache

COMPOSER_HOME=/root composer install

pushd /var/www/api.helioviewer.org/install
python3 -m venv venv
venv/bin/python -m pip install -r test_requirements.txt
popd

bash /root/api_config.sh

chmod 777 /var/www/api.helioviewer.org/log

source /etc/apache2/envvars
touch $READY_FILE
/usr/sbin/apache2 -DFOREGROUND
