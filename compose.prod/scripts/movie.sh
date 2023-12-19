#!/bin/sh
set -e
cp /run/secrets/api_config  settings/Config.ini
cp /run/secrets/api_private settings/Private.php
cd scripts
tcsh movie_queue.tcsh && tail -F /dev/null