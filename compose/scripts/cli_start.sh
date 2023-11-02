#!/bin/sh
mv /root/2021_06_01__00_01_29_132__SDO_AIA_AIA_304.jp2 /tmp/jp2
./headless_setup.sh

SETTINGS_DIR=/root/api/install/settings
sed "s|dbhost = localhost|dbhost = database|" ${SETTINGS_DIR}/settings.example.cfg > ${SETTINGS_DIR}/settings.cfg
sed -i "s|/mnt/data/jp2|/tmp/jp2|" ${SETTINGS_DIR}/settings.cfg
sed -i "s|server = localhost|server=|" ${SETTINGS_DIR}/settings.cfg

tail -f /dev/null
