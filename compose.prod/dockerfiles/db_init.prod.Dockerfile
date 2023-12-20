FROM condaforge/miniforge3:latest
ENV PYTHON_VERSION=3.11.7

RUN useradd -m helioviewer                                         \
 # Allow helioviewer to write to mounted volume
 && mkdir -p /tmp/jp2 && chown -R helioviewer:helioviewer /tmp/jp2 \
 # Need expect for headless setup
 && apt update                                                     \
 && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt install -y expect

WORKDIR /home/helioviewer
USER helioviewer
RUN git clone -b main --single-branch --depth 1 https://github.com/Helioviewer-Project/api.git \
 && conda create -y -n helioviewer python=$PYTHON_VERSION
SHELL ["conda", "run", "-n", "helioviewer", "/bin/bash", "-c"]
# Replace with requirements.txt when it's available in main
RUN pip install numpy sunpy glymur matplotlib scipy \
 && conda install -y mysqlclient

COPY ./compose/2021_06_01__00_01_29_132__SDO_AIA_AIA_304.jp2 /tmp
COPY ./compose.prod/scripts/init_db.sh /home/helioviewer

VOLUME ["/tmp/jp2"]

ENTRYPOINT ["conda", "run", "-n", "helioviewer", "/bin/bash", "/home/helioviewer/init_db.sh"]