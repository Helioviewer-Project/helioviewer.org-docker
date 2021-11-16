FROM ubuntu:20.04

# Environment variables
ENV SITEROOT=/var/www-api
ENV TZ=US/Eastern

# Setup timezone so installation doesn't ask for GEO
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install required packages
RUN apt update;
RUN apt install -y software-properties-common
RUN add-apt-repository ppa:rock-core/qt4
RUN apt update;
RUN apt upgrade;
RUN apt update
RUN apt install -y wget apache2 php7.4 php7.4-mysql php7.4-curl php-pear php-imagick php-mbstring php-bcmath php-redis libapache2-mod-php mysql-server redis-server imagemagick python3-mysqldb python-tk python3-tk python3-pip ffmpeg git libpng-dev libgsf-1-114 git vim qt4-default qt4-qmake ant
RUN pip3 install sunpy glymur zeep bs4 drms lxml numpy scipy datetime pandas bokeh==2.2.1 matplotlib pathlib joblib sip

# Set up SIP and PyQt4 from source (distributed binaries have been obsoleted)
# Download SIP and PyQt to /tmp
WORKDIR /tmp
RUN wget https://www.riverbankcomputing.com/static/Downloads/sip/4.19.25/sip-4.19.25.tar.gz
RUN wget https://www.riverbankcomputing.com/static/Downloads/PyQt4/4.12.3/PyQt4_gpl_x11-4.12.3.tar.gz

# Unpackage and install SIP
RUN tar zxf sip-4.19.25.tar.gz
WORKDIR /tmp/sip-4.19.25
RUN python3 configure.py
RUN make
RUN make install

# Unpackage and setup PyQt4
WORKDIR /tmp
RUN tar zxf PyQt4_gpl_x11-4.12.3.tar.gz
WORKDIR /tmp/PyQt4_gpl_x11-4.12.3
RUN python3 configure.py --confirm-license
RUN make
RUN make install

RUN rm /etc/apache2/sites-enabled/000-default.conf
COPY helioviewer.conf /etc/apache2/sites-available/helioviewer.conf
RUN ln -s /etc/apache2/sites-available/helioviewer.conf /etc/apache2/sites-enabled/helioviewer.conf
COPY apache2.conf /etc/apache2/apache2.conf
COPY ports.conf /etc/apache2/ports.conf
RUN a2enmod headers
COPY my.cnf /etc/my.cnf

# Copy startup script
COPY startup.sh /root/startup.sh
COPY install.sh /root/install.sh

EXPOSE 80
EXPOSE 81

VOLUME /var/www-api/docroot
VOLUME /var/www-api/api.helioviewer.org
VOLUME /var/www-api/jp2

WORKDIR /root

