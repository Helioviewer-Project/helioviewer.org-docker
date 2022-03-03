start_time=`date -d "30 minutes ago" '+%Y-%m-%d %H:%M:%S'`
python3 /var/www/api.helioviewer.org/install/downloader.py -d lmsal2 -s "$start_time" -l /root/log/downloader.log > /root/log/downloader_proc.log
