set -e
cp /run/secrets/api-config /var/www/api.helioviewer.org/settings/Config.ini
cp /run/secrets/api-private /var/www/api.helioviewer.org/settings/Private.php
cp /run/secrets/config-js /var/www/html/resources/js/Utility/Config.js
cd /var/www/html/resources/build
ant
source /etc/apache2/envvars
/usr/sbin/apache2 -DFOREGROUND
