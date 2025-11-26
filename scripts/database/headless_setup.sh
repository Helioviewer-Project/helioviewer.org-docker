#!/usr/bin/expect -f

set timeout 5
set root_password $::env(MARIADB_ROOT_PASSWORD)
set db_name $::env(HELIOVIEWER_DB_NAME)
set db_user $::env(HELIOVIEWER_DB_USER)
set db_pass $::env(HELIOVIEWER_DB_PASS)
spawn python3 install.py

expect "Location" { send "/tmp/jp2\r" }
expect "Choice" { send "1\r" }
expect "Database" { send "$db_name\r" }
expect "Username" { send "$db_user\r" }
expect "Password" { send "$db_pass\r" }
expect "Database" { send "database\r" }
expect "Choice" { send "1\r" }
expect "Username" { send "root\r" }
expect "Password" { send "$root_password\r" }

expect eof
