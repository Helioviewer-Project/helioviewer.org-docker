FROM dgarciabriseno/helioviewer-api-dev
COPY api/install/kakadu/Kakadu_v6_4_1-00781N_Linux-64-bit-Compiled.tar.gz /kakadu/kdu.tar.gz
WORKDIR /kakadu
RUN <<END_OF_COMMANDS
apt update
apt install -y ruby tcsh
gem install resque
docker-php-ext-configure pcntl
docker-php-ext-install -j $(nproc) pcntl
mv /usr/local/bin/resque /usr/local/bin/_resque
echo "_resque -r redis:6379 \$@" > /usr/local/bin/resque
chmod +x /usr/local/bin/resque
END_OF_COMMANDS

WORKDIR /var/www/api.helioviewer.org/scripts
CMD REDIS_BACKEND=redis:6379 tcsh movie_queue.tcsh && tail -F /dev/null