FROM php:8.0.30-apache
ENV PYTHON_VERSION=3.11.7
ENV PHP_CONF_DIR=/usr/local/etc/php

# Install API dependencies
# Setup kakadu for kdu_* commands
# Setup apache to serve from the docroot folder.
# Install composer for php dependencies
# Copy startup script
ENV APACHE_DOCUMENT_ROOT /var/www/api.helioviewer.org/docroot
COPY ./compose/scripts/install_composer.sh /root
COPY api/install/kakadu/Kakadu_v6_4_1-00781N_Linux-64-bit-Compiled.tar.gz kdu.tar.gz
COPY ./compose.prod/scripts/api.prod.startup.sh /root
COPY ./compose.prod/api.apache.conf /etc/apache2/sites-available/000-default.conf
RUN apt update                                                                                                                        \
 && apt install -y imagemagick git unzip libmariadb-dev                                                                               \
 && git clone --recursive https://github.com/Helioviewer-Project/api /var/www/api.helioviewer.org                                     \
 && docker-php-ext-configure mysqli                                                                                                   \
 && docker-php-ext-configure sockets                                                                                                  \
 && docker-php-ext-configure bcmath                                                                                                   \
 && docker-php-ext-install -j$(nproc) mysqli sockets bcmath                                                                           \
 && pecl install redis                                                                                                                \
 && apt install -y libmagick++-dev                                                                                                    \
 && pecl install imagick                                                                                                              \
 && apt remove -y libmagick++-dev                                                                                                     \
 && apt autoremove -y                                                                                                                 \
 && docker-php-ext-enable redis imagick                                                                                               \
 && tar xzf kdu.tar.gz                                                                                                                \
 && mv bin/* /usr/local/bin                                                                                                           \
 && mv lib/* /usr/lib                                                                                                                 \
 && rm -r bin lib                                                                                                                     \
 && sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf                                        \
 && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf                   \
 && bash /root/install_composer.sh                                                                                                    \
 && cd /var/www/api.helioviewer.org && composer install                                                                               \
 && cd /tmp                                                                                                                           \
 && curl -L -X GET https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh --output miniforge.sh \
 && bash miniforge.sh -b -p /tmp/miniforge3                                                                                           \
 && rm miniforge.sh                                                                                                                   \
 && export PATH=$PATH:/tmp/miniforge3/bin                                                                                             \
 && mamba create -n helioviewer -y python=$PYTHON_VERSION                                                                             \
 && mamba init                                                                                                                        \
 && rm $PHP_CONF_DIR/php.ini-development                                                                                              \
 && mv $PHP_CONF_DIR/php.ini-production $PHP_CONF_DIR/php.ini                                                                         \
 && a2enmod rewrite

WORKDIR /var/www/api.helioviewer.org
ENTRYPOINT ["bash", "--login", "/root/api.prod.startup.sh"]
