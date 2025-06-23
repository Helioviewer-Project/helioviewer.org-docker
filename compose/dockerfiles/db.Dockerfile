FROM mariadb
WORKDIR /root
RUN apt update
RUN apt install -y python3 python3-pip python3-dev default-libmysqlclient-dev build-essential pkg-config expect
ENV PIP_BREAK_SYSTEM_PACKAGES=1
RUN python3 -m pip install numpy==2.3.0 sunpy==6.1.1 glymur==0.14.2 matplotlib==3.10.3 scipy==1.15.3 mysql-connector-python==9.3.0


COPY api/install .
COPY compose/2021_06_01__00_01_21_347__SDO_AIA_AIA_171.jp2 img/2021_06_01__00_01_21_347__SDO_AIA_AIA_171.jp2
COPY compose/2021_06_01__00_01_29_132__SDO_AIA_AIA_304.jp2 img/2021_06_01__00_01_29_132__SDO_AIA_AIA_304.jp2
COPY compose/scripts/headless_setup.sh .
COPY compose/scripts/download_test_data.sh .
COPY compose/scripts/downloader.expect .
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
    sleep 10 \
    && ./headless_setup.sh \
    && mariadb -phelioviewer -e "GRANT ALL ON helioviewer.* to 'helioviewer'@'%'" \
    && sed 's!server = localhost!server=!g' settings/settings.example.cfg > settings/settings.cfg \
    && sed -i 's!/mnt/data/!/tmp/!g' settings/settings.cfg \
    && bash download_test_data.sh \
    && pkill mariadb
EOF
