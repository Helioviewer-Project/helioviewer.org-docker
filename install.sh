# Startup background services
source startup.sh

API_DIR=/var/www-api/api.helioviewer.org
SITE_DIR=/var/www-api/docroot

# PERMISSIONS
cd $SITE_DIR
su www-data -s /bin/bash -c 'mkdir -p log cache'

# Set up Kakadu inside the api folder.
cd $API_DIR
su www-data -s /bin/bash -c 'tar zxvpf install/kakadu/Kakadu_v6_4_1-00781N_Linux-64-bit-Compiled.tar.gz'
cp -r lib/* /usr/local/lib/
cp -r bin/* /usr/local/bin
/sbin/ldconfig

# Create configuration files.
cd $API_DIR/settings
cp Config.Example.ini Config.ini
cp Private.Example.php Private.php

cd $API_DIR/install
python3 install.py