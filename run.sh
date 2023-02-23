API_PATH=`pwd`/api
HELIOVIEWER_PATH=`pwd`/helioviewer.org
CONTAINER=dgarciabriseno/helioviewer.org
if [ -n "$1" ]; then CONTAINER=$1; fi

docker run --platform linux/x86_64 -p 127.0.0.1:8080:80 -p 127.0.0.1:8081:81 -v "$API_PATH:/home/helioviewer/api.helioviewer.org" -v "$HELIOVIEWER_PATH:/home/helioviewer/helioviewer.org" -d -t $CONTAINER
