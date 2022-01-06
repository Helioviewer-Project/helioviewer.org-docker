source vars.sh

cd /root/
unzip -qo 2021.zip -d /var/www/jp2
rm 2021.zip

# Set up Kakadu inside the api folder.
cd $API_DIR/install/kakadu
su www-data -s /bin/bash -c 'tar zxvpf Kakadu_v6_4_1-00781N_Linux-64-bit-Compiled.tar.gz'
mv lib/* /usr/local/lib/
mv bin/* /usr/local/bin/
/sbin/ldconfig

cd $API_DIR/install
python3 install.py
