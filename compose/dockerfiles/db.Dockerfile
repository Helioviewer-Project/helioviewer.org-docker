FROM mariadb
WORKDIR /root
RUN apt update
RUN apt install -y python3 python3-pip python3-dev default-libmysqlclient-dev build-essential pkg-config expect
RUN python3 -m pip install numpy sunpy glymur matplotlib scipy mysqlclient

COPY api/install .
COPY compose/2021_06_01__00_01_21_347__SDO_AIA_AIA_171.jp2 img/2021_06_01__00_01_21_347__SDO_AIA_AIA_171.jp2
COPY compose/2021_06_01__00_01_29_132__SDO_AIA_AIA_304.jp2 img/2021_06_01__00_01_29_132__SDO_AIA_AIA_304.jp2
COPY compose/scripts/headless_setup.sh .

RUN mkdir -p /tmp/jp2
RUN cp img/* /tmp/jp2
RUN <<EOF
    MARIADB_ROOT_PASSWORD=helioviewer docker-entrypoint.sh mariadbd &
    sleep 5
    ./headless_setup.sh
    mariadb -phelioviewer -e "CREATE USER 'helioviewer'@'%' IDENTIFIED BY 'helioviewer'"
    mariadb -phelioviewer -e "GRANT ALL ON helioviewer.* to 'helioviewer'@'%'"
    pkill mariadb
EOF
