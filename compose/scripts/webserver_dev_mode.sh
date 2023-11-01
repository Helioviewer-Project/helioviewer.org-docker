# Enables developer mode for helioviewer.org
# (Changes urls from helioviewer.org to localhost)
set -e

sed -i "s|https://api.helioviewer.org|http://localhost:8081|" /var/www/html/resources/js/Utility/Config.js
sed -i "s|https://helioviewer.org|http://localhost:8080|" /var/www/html/resources/js/Utility/Config.js

source /etc/apache2/envvars
/usr/sbin/apache2 -DFOREGROUND