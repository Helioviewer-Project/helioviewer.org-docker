FROM php:8.0.30-apache

# Install API dependencies
# Setup kakadu for kdu_* commands
# Setup apache to serve from the docroot folder.
# Install composer for php dependencies
ENV APACHE_DOCUMENT_ROOT /var/www/api.helioviewer.org/docroot
COPY ./compose/scripts/install_composer.sh /root
COPY api/install/kakadu/Kakadu_v6_4_1-00781N_Linux-64-bit-Compiled.tar.gz kdu.tar.gz
RUN apt update                                                                                                              \
    && apt install -y unzip libpng-dev libjpeg-dev libfreetype-dev python3-dev libmariadb-dev python3-venv                                     \
    && curl -s --output imagemagick.zip -X GET https://codeload.github.com/ImageMagick/ImageMagick6/zip/refs/tags/6.9.12-70 \
    && unzip imagemagick.zip                                                                                                \
    && rm imagemagick.zip                                                                                                   \
    && cd ImageMagick6-6.9.12-70                                                                                            \
    && ./configure && make -j$(nproc) && make install                                                                       \
    && cd ..                                                                                                                \
    && rm -rf ImageMagick6-6.9.12-70                                                                                        \
    && docker-php-ext-configure mysqli                                                                                      \
    && docker-php-ext-configure sockets                                                                                     \
    && docker-php-ext-configure bcmath                                                                                      \
    && docker-php-ext-install -j$(nproc) mysqli sockets bcmath                                                              \
    && pecl install redis                                                                                                   \
    && pecl install xdebug                                                                                                  \
    && pecl install imagick                                                                                                 \
    && docker-php-ext-enable redis xdebug imagick                                                                           \
    && curl -X GET "https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz" --output ffmpeg.tar.xz    \
    && tar xf ffmpeg.tar.xz                                                                                                 \
    && mv ffmpeg-6.1-amd64-static/ffmpeg /usr/local/bin                                                                     \
    && rm -rf ffmpeg.tar.xz ffmpeg-6.1-amd64-static                                                                         \
    && tar xzf kdu.tar.gz                                                                                                   \
    && mv bin/* /usr/local/bin                                                                                              \
    && mv lib/* /usr/lib                                                                                                    \
    && rm -r bin lib                                                                                                        \
    && sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf                           \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf      \
    && bash /root/install_composer.sh

# Enable remote debugging with xdebug
COPY ./compose/99-xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
# Copy the startup script over.
COPY ./compose/scripts/api_config.sh /root
COPY ./compose/scripts/api_startup.sh /root
WORKDIR /var/www/api.helioviewer.org
ENTRYPOINT ["bash", "/root/api_startup.sh"]