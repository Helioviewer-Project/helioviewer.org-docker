#!/usr/bin/expect -f

set timeout 5
set root_password $::env(MARIADB_ROOT_PASSWORD)
spawn python3 install.py

expect "Location" { send "/tmp/jp2\r" }
expect "Choice" { send "1\r" }
expect "Database" { send "\r" }
expect "Username" { send "\r" }
expect "Password" { send "\r" }
expect "Database" { send "database\r" }
expect "Choice" { send "1\r" }
expect "Username" { send "root\r" }
expect "Password" { send "$root_password\r" }

expect eof
