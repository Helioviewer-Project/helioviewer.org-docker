#!/bin/bash
set -e

mkdir -p /var/www/helioviewer.org/cache/tiles
chmod 777 /var/www/helioviewer.org/cache/tiles

COMPOSER_HOME=/root composer install
/var/www/api.helioviewer.org/vendor/bin/start_hgs2hpc

bash /root/api_config.sh

source /etc/apache2/envvars
/usr/sbin/apache2 -DFOREGROUND
