FROM alpine:3.19 as builder
RUN <<EOF
apk update
apk add libgsf-dev git g++ cmake make
git clone https://github.com/Helioviewer-Project/esajpip-SWHV.git
mkdir build && cd build
cmake ../esajpip-SWHV/ -DCMAKE_INSTALL_PREFIX=/home/esajpip -DSWHV_PORT_JPIP=8090 -DSWHV_DIR_IMAGE=/home/esajpip/images -DSWHV_DIR_LOG=/home/esajpip/log
make -j$(nproc) install
cd /home/esajpip
tar zcf /esajpip.tar.gz lib server
EOF

FROM alpine:3.19
COPY --from=builder /esajpip.tar.gz /esajpip.tar.gz
RUN <<EOF
apk update
apk add --no-cache libgsf libstdc++
adduser -D esajpip
cd /home/esajpip
mv /esajpip.tar.gz .
tar xf esajpip.tar.gz
rm esajpip.tar.gz
EOF
VOLUME ["/home/esajpip/images"]
RUN ln -s /home/esajpip/images /tmp/jp2

WORKDIR /home/esajpip/server/esajpip
USER esajpip
ENTRYPOINT ["/home/esajpip/server/esajpip/esajpip"]
