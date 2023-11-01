#!/bin/bash
set -e
source /etc/apache2/envvars

mkdir -p /var/www/helioviewer.org/cache/tiles
chmod 777 /var/www/helioviewer.org/cache/tiles

COMPOSER_HOME=/root composer install
/var/www/api.helioviewer.org/vendor/bin/start_hgs2hpc
/usr/sbin/apache2 -DFOREGROUND
