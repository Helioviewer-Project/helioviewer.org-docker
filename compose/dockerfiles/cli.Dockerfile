FROM alpine as builder
WORKDIR /root
COPY api/install/kakadu/Kakadu_v6_4_1-00781N_Linux-64-bit-Compiled.tar.gz /root/kdu.tar.gz
RUN tar xzf kdu.tar.gz

FROM alpine
# set home to future user home directory
ENV HOME=/home/admin

# install dependencies and setup kakadu
COPY --from=builder /root/bin/* /usr/local/bin
COPY --from=builder /root/lib/* /usr/lib
WORKDIR $HOME
RUN <<EOF
adduser -D admin
mkdir -p /tmp/jp2 && chown -R admin:admin /tmp/jp2
apk update
apk add --virtual build-deps gcc python3-dev musl-dev mariadb-dev
apk add --no-cache python3 expect gcompat mariadb-connector-c
python3 -m venv venv
venv/bin/pip install --no-cache-dir numpy sunpy matplotlib scipy glymur mysqlclient
apk del --no-cache build-deps
chown -R admin:admin /home/admin
EOF

WORKDIR $HOME
# Copy remaining startup scripts
COPY ./compose/2021_06_01__00_01_29_132__SDO_AIA_AIA_304.jp2 $HOME
COPY ./compose/scripts/cli_start.sh $HOME
COPY ./compose/scripts/headless_setup.sh $HOME

# Create volume for storing jp2 images
VOLUME ["/tmp/jp2"]

USER admin
ENTRYPOINT ["sh", "/home/admin/cli_start.sh"]
