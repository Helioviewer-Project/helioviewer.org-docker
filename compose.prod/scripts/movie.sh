#!/bin/sh
set -e
cp /run/secrets/api-config  /var/www/api.helioviewer.org/settings/Config.ini
cp /run/secrets/api-private /var/www/api.helioviewer.org/settings/Private.php
cd /var/www/api.helioviewer.org/scripts
tcsh movie_queue.tcsh && tail -F /dev/null