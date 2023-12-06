# Sets up the api configuration
set -e

SETTINGS_DIR=/var/www/api.helioviewer.org/settings
tmpfile=/tmp/config.ini
configfile=${SETTINGS_DIR}/Config.ini
sed "s|/var/www-api|/var/www/api.helioviewer.org|" ${SETTINGS_DIR}/Config.Example.ini > $tmpfile
sed -i "s|/var/www/api.helioviewer.org/docroot/cache|/var/www/helioviewer.org/cache|" $tmpfile
sed -i "s|/var/www/api.helioviewer.org/docroot/jp2|/tmp/jp2|" $tmpfile
mv $tmpfile $configfile

echo "acao_url[] = http://localhost:8080" >> ${SETTINGS_DIR}/Config.ini
echo "acao_url[] = http://127.0.0.1:8080" >> ${SETTINGS_DIR}/Config.ini

tmpfile=/tmp/config.ini
configfile=${SETTINGS_DIR}/Private.php
sed 's|"HV_DB_HOST", *"localhost"|"HV_DB_HOST", "database"|' ${SETTINGS_DIR}/Private.Example.php > $tmpfile
sed 's|"HV_REDIS_HOST", *"127.0.0.1"|"HV_REDIS_HOST", "redis"|' $tmpfile > $configfile