FROM php:8.2.30-apache

ENV IMAGEMAGICK_VER=7.1.2-18
ENV FFMPEG_VER=8.1

# Install API dependencies
# Setup kakadu for kdu_* commands
# Setup apache to serve from the docroot folder.
# Install composer for php dependencies
ENV APACHE_DOCUMENT_ROOT /var/www/api.helioviewer.org/docroot
COPY api/install/kakadu/Kakadu_v6_4_1-00781N_Linux-64-bit-Compiled.tar.gz kdu.tar.gz
RUN <<EOF
apt update
apt install -y unzip libpng-dev libjpeg-dev libfreetype-dev libmariadb-dev
curl -s --output imagemagick.zip -X GET https://codeload.github.com/ImageMagick/ImageMagick/zip/refs/tags/$IMAGEMAGICK_VER
unzip imagemagick.zip
rm imagemagick.zip
cd ImageMagick-$IMAGEMAGICK_VER && ./configure && make -j$(nproc) && make install && ldconfig
cd ..
rm -rf ImageMagick-$IMAGEMAGICK_VER
curl --output ffmpeg-$FFMPEG_VER.tar.xz https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VER.tar.xz
tar xf ffmpeg-$FFMPEG_VER.tar.xz
rm ffmpeg-$FFMPEG_VER.tar.xz
cd ffmpeg-$FFMPEG_VER
apt install -y build-essential nasm libx264-dev libvpx-dev
./configure --enable-gpl --enable-libx264 --enable-libvpx
make -j $(nproc)
make install
apt remove build-essential nasm
apt clean
cd ..
rm -rf ffmpeg-$FFMPEG_VER
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
a2enmod rewrite
EOF

# Enable remote debugging with xdebug
COPY ./compose/99-xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
COPY --from=composer/composer:latest-bin /composer /usr/bin/composer
WORKDIR /var/www/api.helioviewer.org
