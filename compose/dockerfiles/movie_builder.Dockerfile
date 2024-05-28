FROM dgarciabriseno/helioviewer-api-dev
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
ENTRYPOINT ["/bin/bash", "-c"]
ENV REDIS_BACKEND=redis:6379
CMD ["tcsh movie_queue.tcsh && tail -F /dev/null"]