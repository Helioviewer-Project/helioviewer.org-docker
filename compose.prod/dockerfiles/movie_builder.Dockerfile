FROM alpine
RUN apk add --no-cache gcompat tcsh php php-pcntl php-bcmath php-mysqli php-simplexml php81-pecl-imagick php81-pecl-redis ruby ffmpeg git \
    && gem install resque            \
    && mv /usr/bin/resque /usr/bin/_resque \
    && echo '_resque -r redis $@' > /usr/bin/resque \
    && chmod +x /usr/bin/resque
COPY api/install/kakadu/Kakadu_v6_4_1-00781N_Linux-64-bit-Compiled.tar.gz /kakadu/kdu.tar.gz
WORKDIR /kakadu
RUN tar xzf kdu.tar.gz          \
    && mv bin/* /usr/local/bin  \
    && mv lib/* /usr/lib        \
    && rm -r bin lib
RUN git clone https://github.com/Helioviewer-Project/api.git /var/www/api.helioviewer.org
WORKDIR /var/www/api.helioviewer.org/scripts
CMD REDIS_BACKEND=redis:6379 tcsh movie_queue.tcsh && tail -F /dev/null