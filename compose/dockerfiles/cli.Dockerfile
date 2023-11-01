FROM alpine
WORKDIR /root
COPY ./compose/2021_06_01__00_01_29_132__SDO_AIA_AIA_304.jp2 /root
COPY ./compose/scripts/cli_start.sh /root
COPY ./compose/scripts/headless_setup.sh /root

RUN apk update                                                           \
    && apk add --virtual build-deps gcc python3-dev musl-dev             \
    && apk add --no-cache python3 py3-pip expect mariadb-dev gcompat     \
    && python3 -m pip install --no-cache-dir numpy sunpy matplotlib scipy glymur mysqlclient \
    && apk del build-deps                                                \
    && adduser helioviewer -D

COPY api/install/kakadu/Kakadu_v6_4_1-00781N_Linux-64-bit-Compiled.tar.gz /kakadu/kdu.tar.gz
WORKDIR /kakadu
RUN tar xzf kdu.tar.gz          \
    && mv bin/* /usr/local/bin  \
    && mv lib/* /usr/lib        \
    && rm -r bin lib

WORKDIR /root
ENTRYPOINT ["sh", "/root/cli_start.sh"]
