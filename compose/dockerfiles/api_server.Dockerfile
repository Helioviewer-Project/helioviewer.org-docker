FROM php:8.2.25-apache

# Install API dependencies
# Setup kakadu for kdu_* commands
# Setup apache to serve from the docroot folder.
# Install composer for php dependencies
ENV APACHE_DOCUMENT_ROOT /var/www/api.helioviewer.org/docroot
COPY api/install/kakadu/Kakadu_v6_4_1-00781N_Linux-64-bit-Compiled.tar.gz kdu.tar.gz
RUN <<EOF
apt update
apt install -y unzip libpng-dev libjpeg-dev libfreetype-dev python3-dev libmariadb-dev python3-venv ffmpeg
curl -s --output imagemagick.zip -X GET https://codeload.github.com/ImageMagick/ImageMagick6/zip/refs/tags/6.9.12-70
unzip imagemagick.zip
rm imagemagick.zip
cd ImageMagick6-6.9.12-70 && ./configure && make -j$(nproc) && make install
cd ..
rm -rf ImageMagick6-6.9.12-70
docker-php-ext-configure mysqli
docker-php-ext-configure sockets
docker-php-ext-configure bcmath
docker-php-ext-install -j$(nproc) mysqli sockets bcmath
pecl install redis
pecl install xdebug
pecl install imagick
docker-php-ext-enable redis xdebug imagick
tar xzf kdu.tar.gz
mv bin/* /usr/local/bin
mv lib/* /usr/lib
rm -r bin lib
sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
EOF

# Enable remote debugging with xdebug
COPY ./compose/99-xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
# Copy the startup script over.
COPY ./compose/scripts/api_config.sh /root
COPY ./compose/scripts/api_startup.sh /root
COPY --from=composer/composer:latest-bin /composer /usr/bin/composer
WORKDIR /var/www/api.helioviewer.org
ENTRYPOINT ["bash", "/root/api_startup.sh"]
