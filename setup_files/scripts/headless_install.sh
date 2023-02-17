#!/usr/bin/expect -f

set timeout 5
spawn ./install.sh

expect "Location" { send "/tmp/jp2\r" }
expect "Choice" { send "1\r" }
expect "Database" { send "\r" }
expect "Username" { send "\r" }
expect "Password" { send "\r" }
expect "Database" { send "\r" }
expect "Choice" { send "1\r" }
expect "Username" { send "\r" }
expect "Password" { send "\r" }

expect eof
