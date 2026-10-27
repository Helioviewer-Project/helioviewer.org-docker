#!/bin/sh
set -e

if [ "$ENV" = "dev" ]; then
    cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini
else
    cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini
fi

exec docker-php-entrypoint "$@"
