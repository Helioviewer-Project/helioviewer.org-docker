API_DIR=/tmp/api-master

# Set up Kakadu inside the api folder.
cd $API_DIR/install/kakadu
tar zxvpf Kakadu_v6_4_1-00781N_Linux-64-bit-Compiled.tar.gz
sudo mv lib/* /usr/lib/
sudo mv bin/* /usr/local/bin/
sudo ldconfig

cd $API_DIR/install
python3 install.py
