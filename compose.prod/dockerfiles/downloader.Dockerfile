FROM condaforge/miniforge3:latest
ENV PYTHON_VERSION=3.11.7

RUN useradd -m helioviewer
RUN mkdir -p /tmp/jp2 && chown -R helioviewer:helioviewer /tmp/jp2

WORKDIR /home/helioviewer
USER helioviewer
RUN git clone -b main --single-branch https://github.com/Helioviewer-Project/api.git
USER root
WORKDIR /home/helioviewer/api/install/kakadu
RUN tar xf Kakadu_v6_4_1-00781N_Linux-64-bit-Compiled.tar.gz
RUN mv bin/* /usr/local/bin
RUN mv lib/* /usr/lib
USER helioviewer
RUN conda create -y -n helioviewer python=$PYTHON_VERSION
SHELL ["conda", "run", "-n", "helioviewer", "/bin/bash", "-c"]
# use requirements.txt when it's available
RUN pip install sunpy matplotlib scipy glymur
RUN conda install -y mysqlclient
COPY ./compose.prod/scripts/downloader.sh .
ENTRYPOINT ["conda", "run", "--live-stream", "-n", "helioviewer", "/bin/bash", "downloader.sh"]