FROM ubuntu:20.04

# Environment variables
ENV TZ=US/Eastern

# Setup timezone so installation doesn't ask for geo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install required packages
RUN apt update;
RUN apt upgrade;
RUN apt update
RUN apt install -y wget apache2 php7.4 php7.4-mysql php7.4-curl php-pear php-imagick php-mbstring php-bcmath php-redis libapache2-mod-php mysql-server redis-server imagemagick python3-mysqldb python-tk python3-tk python3-pip ffmpeg git libpng-dev libgsf-1-114 git vim ant
RUN pip3 install sunpy glymur zeep bs4 drms lxml numpy scipy datetime pandas bokeh==2.2.1 matplotlib pathlib joblib

# Copy server configuration files
RUN rm /etc/apache2/sites-enabled/000-default.conf
COPY setup_files/server/helioviewer.conf /etc/apache2/sites-available/helioviewer.conf
COPY setup_files/server/apache2.conf /etc/apache2/apache2.conf
COPY setup_files/server/ports.conf /etc/apache2/ports.conf
COPY setup_files/server/my.cnf /etc/my.cnf

# Enable the site and apache plugins
RUN a2ensite helioviewer
RUN a2enmod headers

# Copy config files
COPY setup_files/app_config /root/app_config

# Copy helpful scripts
COPY setup_files/scripts/startup.sh /root/startup.sh
COPY setup_files/scripts/install.sh /root/install.sh

# Open container ports to the host
EXPOSE 80
EXPOSE 81

# Set up mount points for the devleopment folders
VOLUME /var/www-api/docroot
VOLUME /var/www-api/api.helioviewer.org
VOLUME /var/www-api/jp2

WORKDIR /root

