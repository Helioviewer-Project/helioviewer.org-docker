FROM alpine
WORKDIR /root
COPY ./compose/2021_06_01__00_01_29_132__SDO_AIA_AIA_304.jp2 /root
COPY ./compose/cli_start.sh /root
COPY ./compose/headless_setup.sh /root

RUN apk update                                                           \
    && apk add --virtual build-deps gcc python3-dev musl-dev             \
    && apk add --no-cache python3 py3-pip expect mariadb-dev             \
    && python3 -m pip install --no-cache-dir numpy sunpy matplotlib scipy glymur mysqlclient \
    && apk del build-deps
ENTRYPOINT ["sh", "/root/cli_start.sh"]