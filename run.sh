# Change this to the location of your extracted sample data
JP2_PATH=`pwd`/sample-data
API_PATH=`pwd`/api
HELIOVIEWER_PATH=`pwd`/helioviewer.org
#CONTAINER=helioviewer-dev:test
CONTAINER=dgarciabriseno/helioviewer.org

docker run --platform linux/x86_64 -p 127.0.0.1:8080:80 -p 127.0.0.1:8081:81 -v "$API_PATH:/home/helioviewer/api.helioviewer.org" -v "$HELIOVIEWER_PATH:/home/helioviewer/helioviewer.org" -d -t $CONTAINER
