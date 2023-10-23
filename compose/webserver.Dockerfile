FROM php:8.0.27-apache
RUN docker-php-ext-configure mysqli && docker-php-ext-install -j$(nproc) mysqli
