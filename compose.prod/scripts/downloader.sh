#!/bin/bash
set -e
cd ~/api/install
cp /run/secrets/api_settings settings/settings.cfg
python downloader.py $@
