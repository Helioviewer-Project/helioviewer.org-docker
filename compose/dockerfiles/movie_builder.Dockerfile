FROM php:8.0.30-cli
COPY api/install/kakadu/Kakadu_v6_4_1-00781N_Linux-64-bit-Compiled.tar.gz /kakadu/kdu.tar.gz
WORKDIR /kakadu
RUN <<END_OF_COMMANDS
tar xf kdu.tar.gz
mv bin/* /usr/local/bin
mv lib/* /usr/local/lib
apt update && apt install -y ffmpeg
apt install -y ruby tcsh libmagickwand-dev
printf "\n" | pecl install imagick
echo "extension=imagick.so" > /usr/local/etc/php/conf.d/99-imagick.ini
printf "\n" | pecl install redis
echo "extension=redis.so" > /usr/local/etc/php/conf.d/99-redis.ini
gem install resque
docker-php-ext-configure pcntl
docker-php-ext-install -j $(nproc) pcntl
docker-php-ext-configure bcmath
docker-php-ext-install -j $(nproc) bcmath
docker-php-ext-configure mysqli
docker-php-ext-install -j $(nproc) mysqli
mv /usr/local/bin/resque /usr/local/bin/_resque
echo "_resque -r redis:6379 \$@" > /usr/local/bin/resque
chmod +x /usr/local/bin/resque
useradd movies
mkdir -p /var/www/helioviewer.org/cache/movies
chown -R movies:movies /var/www/helioviewer.org/cache/movies
END_OF_COMMANDS

USER movies
WORKDIR /var/www/api.helioviewer.org/scripts
CMD REDIS_BACKEND=redis:6379 tcsh movie_queue.tcsh && tail -F /dev/null