# Sets up the api configuration
set -e

SETTINGS_DIR=/var/www/api.helioviewer.org/settings
sed "s|/var/www-api|/var/www/api.helioviewer.org|" ${SETTINGS_DIR}/Config.Example.ini > ${SETTINGS_DIR}/Config.ini
sed -i "s|/var/www/api.helioviewer.org/docroot/jp2|/tmp/jp2|" ${SETTINGS_DIR}/Config.ini

echo "acao_url[] = http://localhost:8080" >> ${SETTINGS_DIR}/Config.ini
echo "acao_url[] = http://127.0.0.1:8080" >> ${SETTINGS_DIR}/Config.ini

sed 's|"HV_DB_HOST", *"localhost"|"HV_DB_HOST", "database"|' ${SETTINGS_DIR}/Private.Example.php > ${SETTINGS_DIR}/Private.php
sed -i 's|"HV_REDIS_HOST", *"127.0.0.1"|"HV_REDIS_HOST", "redis"|' ${SETTINGS_DIR}/Private.php