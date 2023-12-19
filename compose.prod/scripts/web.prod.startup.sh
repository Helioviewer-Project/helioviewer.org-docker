cp /run/secrets/api_config /var/www/api.helioviewer.org/settings/Config.ini
cp /run/secrets/api_private /var/www/api.helioviewer.org/settings/Private.php
source /etc/apache2/envvars
/usr/sbin/apache2 -DFOREGROUND
