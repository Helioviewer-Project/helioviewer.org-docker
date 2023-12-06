# Enables developer mode for helioviewer.org
# (Changes urls from helioviewer.org to localhost)
set -e

# sed -i doesn't work for some reason inside the container...
# so instead, manually write the updated config to a tmp file
# then write the final edited config back to the config file.
configfile=/var/www/html/resources/js/Utility/Config.js
tmpconfig=/tmp/tmpconfig
sed "s|https://api.helioviewer.org|http://localhost:8081|" $configfile > $tmpconfig
sed "s|https://helioviewer.org|http://localhost:8080|" $tmpconfig > $configfile
rm $tmpconfig

cd /root
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install 18.16.0

cd /var/www/html/resources/build
npm ci
ant

# Setup background process to rebuild js/css on change
rebuild_on_change() {
    while [ true ]; do
        inotifywait .. -e attrib -r
        ant
    done
}
rebuild_on_change &

source /etc/apache2/envvars
/usr/sbin/apache2 -DFOREGROUND