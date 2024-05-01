FROM php:8.0.30-cli
COPY api/install/kakadu/Kakadu_v6_4_1-00781N_Linux-64-bit-Compiled.tar.gz /kakadu/kdu.tar.gz
WORKDIR /kakadu
RUN tar xf kdu.tar.gz
RUN mv bin/* /usr/local/bin
RUN mv lib/* /usr/local/lib
RUN apt update && apt install -y ffmpeg
RUN apt install -y ruby tcsh libmagickwand-dev
RUN printf "\n" | pecl install imagick
RUN echo "extension=imagick.so" > /usr/local/etc/php/conf.d/99-imagick.ini
RUN printf "\n" | pecl install redis
RUN echo "extension=redis.so" > /usr/local/etc/php/conf.d/99-redis.ini
RUN gem install resque
RUN docker-php-ext-configure pcntl
RUN docker-php-ext-install -j $(nproc) pcntl
RUN docker-php-ext-configure bcmath
RUN docker-php-ext-install -j $(nproc) bcmath
RUN docker-php-ext-configure mysqli
RUN docker-php-ext-install -j $(nproc) mysqli
RUN mv /usr/local/bin/resque /usr/local/bin/_resque
RUN echo "_resque -r redis:6379 \$@" > /usr/local/bin/resque
RUN chmod +x /usr/local/bin/resque
RUN useradd movies
RUN mkdir -p /var/www/helioviewer.org/cache/movies
RUN chown -R movies:movies /var/www/helioviewer.org/cache/movies
VOLUME /var/www/helioviewer.org/cache
USER movies
WORKDIR /var/www/api.helioviewer.org/scripts
CMD REDIS_BACKEND=redis:6379 tcsh movie_queue.tcsh && tail -F /dev/null