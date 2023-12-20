FROM alpine
ENV REDIS_BACKEND=redis:6379
ENV GEM_HOME=/home/helioviewer/gems
COPY api/install/kakadu/Kakadu_v6_4_1-00781N_Linux-64-bit-Compiled.tar.gz /kakadu/kdu.tar.gz
COPY ./compose/scripts/install_composer.sh /root
RUN apk add --no-cache gcompat tcsh php php-pcntl php-bcmath php-mysqli                                            \
        php-simplexml php82-tokenizer php82-dom php82-mbstring php82-phar                                          \
        php82-xmlwriter php82-xml php82-pecl-imagick php82-pecl-redis                                              \
        ruby ffmpeg git                                                                                            \
 && cd /kakadu && tar xzf kdu.tar.gz                                                                               \
 && mv bin/* /usr/local/bin                                                                                        \
 && mv lib/* /usr/lib                                                                                              \
 && rm -r bin lib                                                                                                  \
 && adduser -h /home/helioviewer -D helioviewer                                                                    \
 && touch /home/helioviewer/resque && chown helioviewer:helioviewer /home/helioviewer/resque                       \
 && ln -s /home/helioviewer/resque /usr/bin/resque                                                                 \
 && mkdir -p /var/www && chown -R helioviewer:helioviewer /var/www                                                 \
 && mkdir -p /var/www/helioviewer.org/cache && chown -R helioviewer:helioviewer /var/www/helioviewer.org/cache     \
 && cd /root                                                                                                       \
 && sh install_composer.sh
USER helioviewer
WORKDIR /var/www
RUN git clone -b main --single-branch --depth 1 https://github.com/Helioviewer-Project/api.git /var/www/api.helioviewer.org \
 && mkdir -p /var/www/api.helioviewer.org/log                                                                               \
 && gem install resque                                                                                                      \
 && echo -e "#!/bin/sh\n~/gems/bin/resque -r redis \$@" > /home/helioviewer/resque                                          \
 && chmod +x /home/helioviewer/resque                                                                                       \
 && cd /var/www/api.helioviewer.org                                                                                         \
 && composer install

VOLUME ["/var/www/api.helioviewer.org/log", "/var/www/helioviewer.org/cache"]
COPY ./compose.prod/scripts/movie.sh movie.sh
ENTRYPOINT ["/bin/sh", "movie.sh"]