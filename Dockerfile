FROM oraclelinux:8
ENV INSTALL_PATH=/root/.install

# Download, Compile, and Install PHP8
WORKDIR ${INSTALL_PATH}
RUN dnf update
RUN dnf install -y xz gcc make readline-devel libxml2-devel httpd-devel httpd autoconf
RUN curl -s --output php8.tar.xz -X GET https://www.php.net/distributions/php-8.2.3.tar.xz
RUN tar xf php8.tar.xz
WORKDIR ${INSTALL_PATH}/php-8.2.3
RUN mkdir /etc/php.d; cp php.ini-production /etc/php.ini;
RUN ./configure --with-apxs2=/usr/bin/apxs --with-openssl --with-pear --with-mysqli --with-readline --enable-fpm --enable-phpdbg --without-iconv --without-sqlite3 --without-pdo-sqlite --with-config-file-path=/etc --with-config-file-scan-dir=/etc/php.d; make; make install;
RUN sed "s/NONE/\/usr\/local/" sapi/fpm/php-fpm.conf > /usr/local/etc/php-fpm.conf
RUN mkdir -p /etc/php-fpm.d
RUN cp sapi/fpm/www.conf /usr/local/etc/php-fpm.d
RUN echo $'<FilesMatch \.php$>\nSetHandler application/x-httpd-php\n</FilesMatch>' > /etc/httpd/conf.modules.d/20-php.conf
RUN echo "DirectoryIndex index.html index.php" > /etc/httpd/conf.modules.d/30-indexes.conf
RUN yes '' | pecl install redis
RUN yes '' | pecl install imagick
RUN echo "extension=redis.so" > /etc/php.d/redis.ini
RUN echo "extension=imagick.so" > /etc/php.d/imagick.ini

# Get ffmpeg for making videos
WORKDIR ${INSTALL_PATH}
RUN curl -s --output ffmpeg.tar.xz -X GET https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz
RUN tar xf ffmpeg.tar.xz
RUN install ffmpeg-5.1.1-amd64-static/ffmpeg /usr/local/bin/ffmpeg

# Get image magick
RUN dnf install -y unzip
RUN curl -s --output imagemagick.zip -X GET https://codeload.github.com/ImageMagick/ImageMagick6/zip/refs/tags/6.9.12-70
RUN unzip imagemagick.zip
WORKDIR ${INSTALL_PATH}/ImageMagick6-6.9.12-70
RUN ./configure; make; make install

# Install dependencies
RUN dnf install -y tcsh ruby wget redis vim ant cronie python38
# MySQL is special on enterprise linux
RUN dnf install -y https://repo.mysql.com/mysql80-community-release-el8.rpm
RUN dnf config-manager --disable mysql*; dnf config-manager --enable mysql80-community; dnf module disable -y mysql
RUN dnf install -y mysql-community-server mysql-community-devel
USER mysql
RUN mysqld --initialize-insecure


# Helioviewer dependencies
USER root
RUN dnf install -y python38-pip python38-devel expect sudo

# Helioviewer application configuration
RUN python3 -m pip install --user numpy sunpy matplotlib scipy glymur mysqlclient
RUN useradd helioviewer
USER helioviewer

# Helioviewer installation
COPY setup_files/scripts/crontab /home/helioviewer/.crontab
RUN crontab /home/helioviewer/.crontab
WORKDIR /tmp
RUN curl --output api.zip -s -X GET https://codeload.github.com/Helioviewer-Project/api/zip/refs/heads/master
RUN unzip -q api.zip

COPY sample-data/2021.zip /tmp/jp2/2021.zip
WORKDIR ${INSTALL_PATH}/setup_files/scripts
USER root
COPY setup_files ${INSTALL_PATH}/setup_files
RUN mysqld --user=mysql -D; ./headless_install.sh; sh ${INSTALL_PATH}/setup_files/scripts/mysql_user_patch.sh

EXPOSE 80
EXPOSE 81

USER root
RUN echo "helioviewer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers
RUN mkdir -p /home/helioviewer/httpd
RUN chmod +x /home/helioviewer
RUN rm /etc/httpd/conf.d/welcome.conf
# Set up server configuration
COPY setup_files/server/helioviewer.conf /etc/httpd/conf.d/helioviewer.conf
COPY setup_files/server/add_ports.sh ${INSTALL_PATH}/add_ports.sh
COPY setup_files/server/my.cnf /etc/my.cnf.d/my.cnf
RUN sh ${INSTALL_PATH}/add_ports.sh

USER helioviewer
WORKDIR /home/helioviewer
CMD [ "sudo", "bash", "-c", "/root/.install/setup_files/scripts/startup.sh" ]
