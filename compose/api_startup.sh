#!/bin/bash
source /etc/apache2/envvars

mkdir /var/www/helioviewer.org/cache/tiles
chmod 777 /var/www/helioviewer.org/cache/tiles

/var/www/api.helioviewer.org/vendor/bin/start_hgs2hpc
/usr/sbin/apache2 -DFOREGROUND
