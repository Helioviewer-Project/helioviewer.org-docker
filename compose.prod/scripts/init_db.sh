#!/bin/bash
READY_FILE=/tmp/ready
rm -f $READY_FILE
set -e
cp /run/secrets/api_settings api/install/settings/settings.cfg
cp /run/secrets/db_setup_script headless_setup.sh
cp /tmp/2021_06_01__00_01_29_132__SDO_AIA_AIA_304.jp2 /tmp/jp2
chmod +x headless_setup.sh
./headless_setup.sh
touch $READY_FILE
exit 0