# Change this to the location of your extracted sample data
JP2_PATH=`pwd`/../sample-data
API_PATH=`pwd`/api
HELIOVIEWER_PATH=`pwd`/helioviewer.org
CONTAINER=dgarciabriseno/helioviewer.org-docker:latest

docker run -p 127.0.0.1:8080:80 -p 127.0.0.1:8081:81 -v "$API_PATH:/var/www/api.helioviewer.org" -v "$HELIOVIEWER_PATH:/var/www/helioviewer.org" -v "$JP2_PATH:/var/www/jp2" -d -t $CONTAINER
