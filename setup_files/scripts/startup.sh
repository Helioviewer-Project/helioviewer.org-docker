function cleanup()
{
    pkill httpd
    pkill mysqld
    # redis and tcsh don't need graceful cleanup (I hope)

    echo "exited $0"
    exit
}

# USE the trap if you need to also do manual cleanup after the service is stopped,
#     or need to start multiple services in the one container
trap cleanup HUP INT QUIT TERM

cd /root/.install/setup_files/scripts
source first_time_run.sh
source vars.sh
httpd
mysqld --user=mysql -D
redis-server --daemonize yes
# Start up movie builder
nohup tcsh $API_DIR/scripts/movie_queue.tcsh > $API_DIR/log/movie_builder.log

echo "Container up and running"
read
