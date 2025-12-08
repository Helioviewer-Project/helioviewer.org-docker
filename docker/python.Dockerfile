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
    && mv /tmp/bin/* /bin \
    && mv /tmp/lib/* /lib \
    && pip install --no-cache-dir numpy==2.3.0 sunpy==6.1.1 glymur==0.14.2 matplotlib==3.10.3 scipy==1.15.3 mysql-connector-python==9.3.0

ENTRYPOINT [ "python" ]
