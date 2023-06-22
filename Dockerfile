FROM oraclelinux:8
ENV INSTALL_PATH=/root/.install
# Group all heliovewer dependencies into one DNF download
WORKDIR ${INSTALL_PATH}
RUN dnf update -y
RUN dnf --enablerepo=ol8_codeready_builder install -y oniguruma-devel xz gcc make readline-devel \
                            libxml2-devel httpd-devel httpd autoconf libcurl-devel openssl-devel \
                            tcsh redis cronie unzip vim ant python38                             \
                            https://repo.mysql.com/mysql80-community-release-el8.rpm             \
                            python38-pip python38-devel sudo expect libpng-devel

# Enable mysql community server and install it
RUN dnf config-manager --disable mysql* && dnf config-manager --enable mysql80-community && dnf module disable -y mysql
RUN dnf install -y mysql-community-server mysql-community-devel

# Download, Compile, and Install PHP8
RUN curl -s --output php8.tar.xz -X GET https://www.php.net/distributions/php-8.2.3.tar.xz &&      \
    tar xf php8.tar.xz &&                                                                          \
    cd ${INSTALL_PATH}/php-8.2.3 &&                                                                \
    mkdir /etc/php.d && cp php.ini-development /etc/php.ini &&                                     \
    ./configure --with-apxs2=/usr/bin/apxs --with-curl --enable-pcntl --with-openssl --with-pear   \
                --with-mysqli --with-readline --enable-phpdbg --without-iconv --enable-sockets     \
                --enable-mbstring --enable-bcmath                                                  \
                --without-sqlite3 --without-pdo-sqlite --with-config-file-path=/etc                \
                --with-config-file-scan-dir=/etc/php.d &&                                          \
    echo -------------------------------- &&                                                       \
    echo Compiling with $(nproc) threads  &&                                                       \
    echo -------------------------------- &&                                                       \
    make -j$(nproc) &&                                                                             \
    make install &&                                                                                \
    cd ${INSTALL_PATH} &&                                                                          \
    rm -rf php-8.2.3 &&                                                                            \
    rm -rf php8.tar.xz

# Echo all necessary files here
RUN echo $'<FilesMatch \.php$>\nSetHandler application/x-httpd-php\n</FilesMatch>' > /etc/httpd/conf.modules.d/20-php.conf && \
    echo "DirectoryIndex index.html index.php" > /etc/httpd/conf.modules.d/30-indexes.conf &&                                 \
    echo "extension=redis.so" > /etc/php.d/redis.ini &&                                                                       \
    echo "extension=imagick.so" > /etc/php.d/imagick.ini &&                                                                   \
    echo "zend_extension=xdebug.so" > /etc/php.d/xdebug.ini &&                                                                   \
    echo "helioviewer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers &&                                                              \
    echo "export LD_LIBRARY_PATH=/usr/local/lib" >> /etc/bashrc &&                                                            \
    echo '!includedir /etc/my.cnf.d' >> /etc/my.cnf &&                                                                        \
    touch /tmp/sdo-backfill.log /tmp/sdo-monthly.log /tmp/rob-backfill.log /tmp/rob-monthly.log /tmp/soho-backfill.log /tmp/soho-monthly.log /tmp/stereo-backfill.log /tmp/stereo-monthly.log

# Install redis-php add-ons and xdebug
RUN yes '' | pecl install redis && pecl install xdebug

# Get ffmpeg for making videos
RUN curl -s --output ffmpeg.tar.xz -X GET https://www.johnvansickle.com/ffmpeg/old-releases/ffmpeg-5.1.1-amd64-static.tar.xz && \
    tar xf ffmpeg.tar.xz &&                                                                                                     \
    install ffmpeg-5.1.1-amd64-static/ffmpeg /usr/local/bin/ffmpeg &&                                                           \
    rm -rf ffmpeg.tar.xz &&                                                                                                     \
    rm -rf ffmpeg-5.1.1-amd64-static/ffmpeg

# Get image magick
RUN dnf install -y freetype-devel
RUN curl -s --output imagemagick.zip -X GET https://codeload.github.com/ImageMagick/ImageMagick6/zip/refs/tags/6.9.12-70 && \
    unzip imagemagick.zip &&                                                                                                \
    cd ${INSTALL_PATH}/ImageMagick6-6.9.12-70 &&                                                                            \
    ./configure && make -j$(nproc) && make install &&                                                                             \
    yes '' | pecl install imagick &&                                                                                        \
    rm -rf ${INSTALL_PATH}/ImageMagick6-6.9.12-70

# MySQL is special on enterprise linux. Initialize it manually here.
user mysql
RUN mysqld --initialize-insecure

# Helioviewer installation
USER root
RUN useradd helioviewer -m -s /bin/bash && cp /etc/skel/.bash* /home/helioviewer && chown helioviewer:helioviewer /home/helioviewer
USER helioviewer
RUN python3 -m pip install --user numpy sunpy matplotlib scipy glymur mysqlclient
COPY --chown=helioviewer:helioviewer sample-data/2021.zip /tmp/jp2/2021.zip
WORKDIR /tmp/jp2
RUN unzip 2021.zip
WORKDIR /tmp
USER helioviewer
COPY --chown=helioviewer:helioviewer setup_files /home/helioviewer/setup_files
RUN curl --output api.zip -s -X GET https://codeload.github.com/Helioviewer-Project/api/zip/refs/heads/master && \
    unzip -q api.zip &&                                                                                          \
    python3 -m pip install --user -r /tmp/api-master/docs/src/requirements.txt &&                                \
    python3 -m pip install --user -r /tmp/api-master/scripts/availability_feed/requirements.txt &&               \
    cd /home/helioviewer/setup_files/scripts &&                                                                  \
    sudo mysqld --user=mysql -D && ./headless_setup.sh &&                                                        \
    rm -rf /tmp/api.zip /tmp/api-master &&                                                                       \
    sudo pkill mysqld

# Set up server configuration
COPY setup_files/server/helioviewer.conf /etc/httpd/conf.d/helioviewer.conf
COPY setup_files/server/add_ports.sh ${INSTALL_PATH}/add_ports.sh
COPY setup_files/server/my.cnf /etc/my.cnf.d/my.cnf
RUN mkdir -p /home/helioviewer/httpd &&       \
    sudo chmod +x /home/helioviewer &&        \
    sudo rm /etc/httpd/conf.d/welcome.conf && \
    sudo sh ${INSTALL_PATH}/add_ports.sh

# enable npm and composer
USER root
RUN curl -q -X GET https://raw.githubusercontent.com/composer/getcomposer.org/76a7060ccb93902cd7576b67264ad91c8a2700e2/web/installer | php && \
    mv composer.phar /usr/bin/composer &&                                                                                                     \
    curl -X GET --output node.tar.xz https://nodejs.org/dist/v18.16.0/node-v18.16.0-linux-x64.tar.xz &&                                       \
    tar xf node.tar.xz &&                                                                                                                     \
    cd node-v18.16.0-linux-x64/bin &&                                                                                                         \
    ln -s $PWD/* /usr/bin &&                                                                                                                  \
    cd ../.. && rm -rf node.tar.xz

USER helioviewer
COPY setup_files/scripts/crontab /home/helioviewer/.crontab
RUN crontab /home/helioviewer/.crontab
WORKDIR /home/helioviewer


# Web server port
EXPOSE 80
# API server port
EXPOSE 81
# xdebug remote connection port
EXPOSE 9003

CMD [ "bash", "-c", "/home/helioviewer/setup_files/scripts/startup.sh" ]
