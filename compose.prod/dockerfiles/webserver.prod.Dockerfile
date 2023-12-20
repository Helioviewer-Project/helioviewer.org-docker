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
# This isn't technically a secret, but it should be treated like the other config files.
# Must be copied after cloning helioviewer.org, but before running `ant`
COPY ./secrets/Config.js /var/www/html/resources/js/Utility/Config.js
RUN nvm install 20.10.0                            \
 && cd /var/www/html/resources/build               \
 && ant                                            \
 && apt remove -y ant python3 && apt -y autoremove \
 && rm $PHP_CONF_DIR/php.ini-development           \
 && mv $PHP_CONF_DIR/php.ini-production $PHP_CONF_DIR/php.ini

ENTRYPOINT ["bash", "/root/web.prod.startup.sh"]
# ENTRYPOINT ["tail", "-F", "/dev/null"]
