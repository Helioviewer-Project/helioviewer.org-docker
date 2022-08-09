FROM ubuntu:20.04

# Environment variables
ENV TZ=US/Eastern

# Setup timezone so installation doesn't ask for geo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install required packages
RUN apt update
RUN apt upgrade -y
RUN apt update
RUN apt install -y tcsh ruby wget apache2 php7.4 php7.4-mysql php7.4-curl php-pear php-imagick php-mbstring php-bcmath php-redis libapache2-mod-php mysql-server redis-server imagemagick python3-mysqldb python-tk python3-tk python3-pip ffmpeg git libpng-dev libgsf-1-114 git vim ant cron
RUN pip3 install sunpy==2.0.5 glymur zeep bs4 drms lxml numpy scipy datetime pandas bokeh==2.2.1 matplotlib pathlib joblib
RUN gem install resque

# Get composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php
RUN php -r "unlink('composer-setup.php');"
RUN mv composer.phar /usr/local/bin/composer

# Copy server configuration files
RUN rm /etc/apache2/sites-enabled/000-default.conf
COPY setup_files/server/helioviewer.conf /etc/apache2/sites-available/helioviewer.conf
COPY setup_files/server/apache2.conf /etc/apache2/apache2.conf
COPY setup_files/server/ports.conf /etc/apache2/ports.conf
COPY setup_files/server/my.cnf /etc/my.cnf
COPY setup_files/scripts/crontab /etc/cron.d/crontab
COPY setup_files/welcome_message.txt /etc/motd

# Enable the site and apache plugins
RUN a2ensite helioviewer
RUN a2enmod headers
RUN a2enmod rewrite

# Copy helpful scripts
COPY setup_files /root/setup_files/
RUN crontab /root/setup_files/scripts/crontab
RUN rm /root/setup_files/scripts/crontab

# Make sure the welcome message shows when user enters the console
RUN sh /root/setup_files/scripts/show_motd.sh

# Copy sample data (so users don't need to provide
# their own for the installation to work)
COPY sample-data/* /root/

RUN mkdir /root/log

# Open container ports to the host
EXPOSE 80
EXPOSE 81

# Set up mount points for the devleopment folders
VOLUME /var/www/helioviewer.org
VOLUME /var/www/api.helioviewer.org

# Tell user what more they need to do to complete setup
RUN


WORKDIR /root/setup_files/scripts
CMD [ "bash", "startup.sh" ]
