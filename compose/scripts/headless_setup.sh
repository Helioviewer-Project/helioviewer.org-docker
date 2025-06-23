#!/usr/bin/expect -f

set timeout 5
spawn python3 install.py

expect "Location" { send "/tmp/jp2\r" }
expect "Choice" { send "1\r" }
expect "Database" { send "\r" }
expect "Username" { send "\r" }
expect "Password" { send "\r" }
expect "Database" { send "127.0.0.1\r" }
expect "Choice" { send "1\r" }
expect "Username" { send "root\r" }
expect "Password" { send "helioviewer\r" }

expect eof
