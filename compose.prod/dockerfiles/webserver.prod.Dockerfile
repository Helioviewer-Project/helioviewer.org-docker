FROM php:8.0.30-apache
RUN docker-php-ext-configure mysqli && docker-php-ext-install -j$(nproc) mysqli
RUN apt update && apt install -y git
RUN git clone --recursive https://github.com/Helioviewer-Project/helioviewer.org /var/www/html
# This isn't technically a secret, but it should be treated like the other config files.
COPY ./secrets/Config.js /var/www/html/resources/js/Utility/Config.js
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
SHELL ["bash", "--login", "-c"]
RUN nvm install 20.10.0
WORKDIR /var/www/html/resources/build/
RUN apt install -y ant python3
RUN ant
RUN apt remove -y ant python3 && apt -y autoremove
RUN git clone https://github.com/Helioviewer-Project/api /var/www/api.helioviewer.org
COPY ./compose/scripts/install_composer.sh /root
RUN bash /root/install_composer.sh
RUN apt install -y unzip
WORKDIR /var/www/api.helioviewer.org
RUN composer install
ENV PHP_CONF_DIR=/usr/local/etc/php
RUN rm $PHP_CONF_DIR/php.ini-development
RUN mv $PHP_CONF_DIR/php.ini-production $PHP_CONF_DIR/php.ini

COPY compose.prod/scripts/web.prod.startup.sh /root
ENTRYPOINT ["bash", "/root/web.prod.startup.sh"]
# ENTRYPOINT ["tail", "-F", "/dev/null"]
