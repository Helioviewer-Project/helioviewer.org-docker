# Enables developer mode for helioviewer.org
# (Changes urls from helioviewer.org to localhost)
set -e

sed -i "s|https://api.helioviewer.org|http://localhost:8081|" /var/www/html/resources/js/Utility/Config.js
sed -i "s|https://helioviewer.org|http://localhost:8080|" /var/www/html/resources/js/Utility/Config.js

apt update
apt install -y ant python3

cd /root
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install 18.16.0

cd /var/www/html/resources/build
npm ci
ant

source /etc/apache2/envvars
/usr/sbin/apache2 -DFOREGROUND