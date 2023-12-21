FROM php:8.0.30-apache

ENV PHP_CONF_DIR=/usr/local/etc/php

COPY ./compose/scripts/install_composer.sh /root
COPY compose.prod/scripts/web.prod.startup.sh /root

RUN docker-php-ext-configure mysqli                                                                                     \
 && docker-php-ext-install -j$(nproc) mysqli                                                                            \
 && apt update && apt install -y git ant python3 unzip                                                                  \
 && bash /root/install_composer.sh                                                                                      \
 && rm -rf /var/www/html/*                                                                                              \
 && git clone --recursive https://github.com/Helioviewer-Project/helioviewer.org /var/www/html                          \
 && git clone -b main --single-branch --depth 1 https://github.com/Helioviewer-Project/api /var/www/api.helioviewer.org \
 && cd /var/www/api.helioviewer.org && composer install                                                                 \
 && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
SHELL ["bash", "--login", "-c"]
RUN nvm install 20.10.0                            \
 && rm $PHP_CONF_DIR/php.ini-development           \
 && mv $PHP_CONF_DIR/php.ini-production $PHP_CONF_DIR/php.ini

ENTRYPOINT ["bash", "--login", "/root/web.prod.startup.sh"]
# ENTRYPOINT ["tail", "-F", "/dev/null"]
