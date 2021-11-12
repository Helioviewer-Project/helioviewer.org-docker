JP2_PATH=/Path/To/Sample/Data
ROOT_PATH=/Path/To/This/Repo
API_PATH=$ROOT_PATH/api
HELIOVIEWER_PATH=$ROOT_PATH/helioviewer.org

docker run -p 127.0.0.1:8080:80 -p 127.0.0.1:8081:81 -v $API_PATH:/var/www-api/api.helioviewer.org -v $HELIOVIEWER_PATH:/var/www-api/docroot -v $JP2_PATH:/var/www-api/jp2 -d -t helioviewer-dev:latest
