#!/bin/sh
source venv/bin/activate
cp /home/admin/2021_06_01__00_01_29_132__SDO_AIA_AIA_304.jp2 /tmp/jp2
./headless_setup.sh

SETTINGS_DIR=/home/admin/api/install/settings
TMPFILE=/tmp/settings.cfg
sed "s|dbhost = localhost|dbhost = database|" ${SETTINGS_DIR}/settings.example.cfg > $TMPFILE
sed -i "s|/mnt/data/hvpull|/tmp|" $TMPFILE
sed -i "s|/mnt/data/jp2|/tmp/jp2|" $TMPFILE
sed "s|server = localhost|server=|" $TMPFILE > ${SETTINGS_DIR}/settings.cfg

# Download some test data
set -e
cd /home/admin/api/install
python downloader.py -d hv_soho -s "2023-12-01 00:00:00" -e "2023-12-01 01:00:00"

tail -f /dev/null
