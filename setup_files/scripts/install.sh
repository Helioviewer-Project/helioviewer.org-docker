API_DIR=/tmp/api-master

cd /tmp/jp2
unzip -qo 2021.zip

# Set up Kakadu inside the api folder.
cd $API_DIR/install/kakadu
tar zxvpf Kakadu_v6_4_1-00781N_Linux-64-bit-Compiled.tar.gz
mv lib/* /usr/local/lib/
mv bin/* /usr/local/bin/
/sbin/ldconfig

cd $API_DIR/install
python3 install.py
