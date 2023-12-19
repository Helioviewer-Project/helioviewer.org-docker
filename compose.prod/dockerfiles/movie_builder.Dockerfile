FROM alpine
RUN apk add --no-cache gcompat tcsh php php-pcntl php-bcmath php-mysqli   \
        php-simplexml php82-tokenizer php82-dom php82-mbstring php82-phar \
        php82-xmlwriter php82-xml php82-pecl-imagick php82-pecl-redis     \
        ruby ffmpeg git
COPY api/install/kakadu/Kakadu_v6_4_1-00781N_Linux-64-bit-Compiled.tar.gz /kakadu/kdu.tar.gz
WORKDIR /kakadu
RUN tar xzf kdu.tar.gz          \
    && mv bin/* /usr/local/bin  \
    && mv lib/* /usr/lib        \
    && rm -r bin lib
RUN adduser -h /home/helioviewer -D helioviewer
RUN mkdir -p /var/www && chown -R helioviewer:helioviewer /var/www
USER helioviewer
WORKDIR /var/www
RUN git clone -b main --single-branch https://github.com/Helioviewer-Project/api.git /var/www/api.helioviewer.org
ENV REDIS_BACKEND=redis:6379
ENV GEM_HOME=/home/helioviewer/gems
RUN gem install resque
RUN echo -e "#!/bin/sh\n~/gems/bin/resque -r redis \$@" > /home/helioviewer/resque
RUN chmod +x /home/helioviewer/resque
USER root
RUN ln -s /home/helioviewer/resque /usr/bin/resque
RUN mkdir -p /var/www/api.helioviewer.org/log && chown -R helioviewer:helioviewer /var/www/api.helioviewer.org/log
RUN mkdir -p /var/www/helioviewer.org/cache && chown -R helioviewer:helioviewer /var/www/helioviewer.org/cache
USER helioviewer
USER root
COPY ./compose/scripts/install_composer.sh /root
RUN sh /root/install_composer.sh
USER helioviewer
WORKDIR /var/www/api.helioviewer.org
RUN composer install

VOLUME ["/var/www/api.helioviewer.org/log", "/var/www/helioviewer.org/cache"]
COPY ./compose.prod/scripts/movie.sh movie.sh
ENTRYPOINT ["/bin/sh", "movie.sh"]