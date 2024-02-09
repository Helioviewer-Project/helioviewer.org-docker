#!/bin/bash
set -e
cd ~/api/install
cp /run/secrets/api-settings settings/settings.cfg
python downloader.py $@
