FROM mariadb
WORKDIR /root
RUN apt update
RUN apt install -y python3 python3-pip python3-dev default-libmysqlclient-dev build-essential pkg-config expect
RUN python3 -m pip install numpy sunpy glymur matplotlib scipy mysqlclient

COPY api/install .
COPY compose/2021_06_01__00_01_21_347__SDO_AIA_AIA_171.jp2 img/2021_06_01__00_01_21_347__SDO_AIA_AIA_171.jp2
COPY compose/2021_06_01__00_01_29_132__SDO_AIA_AIA_304.jp2 img/2021_06_01__00_01_29_132__SDO_AIA_AIA_304.jp2
COPY compose/scripts/headless_setup.sh .
COPY api/install/kakadu/Kakadu_v6_4_1-00781N_Linux-64-bit-Compiled.tar.gz kdu.tar.gz
RUN <<EOF
tar xzf kdu.tar.gz
mv bin/* /usr/local/bin
mv lib/* /usr/lib
EOF

RUN mkdir -p /tmp/jp2
RUN cp img/* /tmp/jp2
RUN <<EOF
    MARIADB_ROOT_PASSWORD=helioviewer docker-entrypoint.sh mariadbd &
    sleep 5
    ./headless_setup.sh
    mariadb -phelioviewer -e "CREATE USER 'helioviewer'@'%' IDENTIFIED BY 'helioviewer'"
    mariadb -phelioviewer -e "GRANT ALL ON helioviewer.* to 'helioviewer'@'%'"
    sed 's!server = localhost!server=!g' settings/settings.example.cfg > settings/settings.cfg
    sed -i 's!/mnt/data/!/tmp/!g' settings/settings.cfg
    expect -c 'spawn python3 downloader.py -d hv_soho -s "2023-12-01 00:00:00" -e "2023-12-01 01:00:00"; expect "Sleeping for 30 minutes"'
    pkill mariadb
EOF
