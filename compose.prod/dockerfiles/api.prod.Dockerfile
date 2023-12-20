FROM php:8.0.30-apache
ENV PYTHON_VERSION=3.11.7

# Install API dependencies
# Setup kakadu for kdu_* commands
# Setup apache to serve from the docroot folder.
# Install composer for php dependencies
ENV APACHE_DOCUMENT_ROOT /var/www/api.helioviewer.org/docroot
COPY ./compose/scripts/install_composer.sh /root
COPY api/install/kakadu/Kakadu_v6_4_1-00781N_Linux-64-bit-Compiled.tar.gz kdu.tar.gz
RUN apt update
RUN apt install -y imagemagick git
RUN git clone --recursive https://github.com/Helioviewer-Project/api /var/www/api.helioviewer.org
RUN docker-php-ext-configure mysqli
RUN docker-php-ext-configure sockets
RUN docker-php-ext-configure bcmath
RUN docker-php-ext-install -j$(nproc) mysqli sockets bcmath
RUN pecl install redis
RUN apt install -y libmagick++-dev
RUN pecl install imagick
RUN apt remove -y libmagick++-dev
RUN apt autoremove -y
RUN docker-php-ext-enable redis imagick
RUN tar xzf kdu.tar.gz
RUN mv bin/* /usr/local/bin
RUN mv lib/* /usr/lib
RUN rm -r bin lib
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
RUN bash /root/install_composer.sh
WORKDIR /var/www/api.helioviewer.org
RUN apt install -y unzip
RUN composer install
WORKDIR /tmp
RUN curl -L -X GET https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh --output miniforge.sh \
    && bash miniforge.sh -b -p /tmp/miniforge3                                                                                        \
    && rm miniforge.sh
RUN export PATH=$PATH:/tmp/miniforge3/bin                    \
    && mamba create -n helioviewer -y python=$PYTHON_VERSION \
    && mamba init
RUN apt install -y libmariadb-dev

ENV PHP_CONF_DIR=/usr/local/etc/php
RUN rm $PHP_CONF_DIR/php.ini-development
RUN mv $PHP_CONF_DIR/php.ini-production $PHP_CONF_DIR/php.ini

# Copy the startup script over.
COPY ./compose.prod/scripts/api.prod.startup.sh /root
WORKDIR /var/www/api.helioviewer.org
ENTRYPOINT ["bash", "--login", "/root/api.prod.startup.sh"]
# ENTRYPOINT ["tail", "-F", "/dev/null"]
