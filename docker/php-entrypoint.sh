#!/bin/sh
set -e

if [ "$ENV" = "dev" ]; then
    export PHPRC=/usr/local/etc/php/dev
else
    export PHPRC=/usr/local/etc/php/prod
fi

exec docker-php-entrypoint "$@"
