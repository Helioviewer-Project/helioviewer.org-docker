FROM python:3

# Install build dependencies including gfortran, cmake, and OpenBLAS for scipy
COPY api/install/kakadu/Kakadu_v6_4_1-00781N_Linux-64-bit-Compiled.tar.gz kdu.tar.gz
RUN apt-get update && apt-get install -y --no-install-recommends \
    gfortran \
    cmake \
    libopenblas-dev \
    expect \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/* \
    && tar xzf kdu.tar.gz -C /tmp \
    && cp /tmp/bin/* /bin \
    && cp /tmp/lib/* /lib \
    && mv /tmp/bin/* /usr/local/bin \
    && mv /tmp/lib/* /usr/local/lib \
    && pip install --no-cache-dir numpy==2.3.5 \
                                  sunpy==7.1.0 \
                                  Glymur==0.14.4 \
                                  matplotlib==3.10.7 \
                                  scipy==1.16.3 \
                                  mysql-connector-python==9.5.0 \
                                  pytest==9.0.2 \
                                  responses==0.25.8 \
                                  reproject==0.19.0 \
                                  mpl-animators==1.2.4 \
                                  beautifulsoup4==4.14.3 \
                                  drms==0.9.0 \
                                  zeep==4.3.2

ENTRYPOINT [ "python" ]
