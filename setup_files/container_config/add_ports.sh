conf_path=/etc/httpd/conf/httpd.conf
tmp_path=/tmp/httpd.conf
sed "s/Listen 80/Listen 80\n\
Listen 81\n\
<IfModule ssl_module>\n\
  Listen 443\n\
<\/IfModule>/" $conf_path > $tmp_path
mv $tmp_path $conf_path
