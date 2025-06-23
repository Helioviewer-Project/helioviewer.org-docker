# Enables developer mode for helioviewer.org
# (Changes urls from helioviewer.org to localhost)
set -e

# sed -i doesn't work for some reason inside the container...
# so instead, manually write the updated config to a tmp file
# then write the final edited config back to the config file.
configfile=/var/www/html/resources/js/Utility/Config.js
tmpconfig=/tmp/tmpconfig
sed "s|https://api.helioviewer.org|http://$API_HOST:$API_PORT|" $configfile > $tmpconfig
sed "s|https://helioviewer.org|http://$HV_HOST:$CLIENT_PORT|" $tmpconfig > $configfile
rm $tmpconfig

cd /root
# Check if nvm is already installed
if [ ! -d "$HOME/.nvm" ]; then
    echo "nvm not found, installing..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
else
    echo "nvm is already installed"
fi

# Set up nvm environment
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Install Node.js version 18.16.0 if not already installed
if ! nvm list | grep -q "v18.16.0"; then
    echo "Installing Node.js v18.16.0"
    nvm install 18.16.0
else
    echo "Node.js v18.16.0 is already installed"
fi
source /etc/apache2/envvars
/usr/sbin/apache2 -DFOREGROUND
