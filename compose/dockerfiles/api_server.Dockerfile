FROM php:8.0.27-apache

RUN apt update                                                                                                              \
    && apt install -y unzip libpng-dev libjpeg-dev python3 python3-venv                                                                \
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
    && docker-php-ext-enable redis xdebug imagick

COPY api/install/kakadu/Kakadu_v6_4_1-00781N_Linux-64-bit-Compiled.tar.gz /kakadu/kdu.tar.gz
WORKDIR /kakadu
RUN tar xzf kdu.tar.gz          \
    && mv bin/* /usr/local/bin  \
    && mv lib/* /usr/lib        \
    && rm -r bin lib

ENV APACHE_DOCUMENT_ROOT /var/www/api.helioviewer.org/docroot
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

COPY ./compose/99-xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

COPY ./compose/scripts/api_startup.sh /root
WORKDIR /var/www/api.helioviewer.org
ENTRYPOINT ["bash", "/root/api_startup.sh"]
# ENTRYPOINT ["tail", "-F", "/dev/null"]