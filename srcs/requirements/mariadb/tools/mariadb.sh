#!/bin/bash
set -e

# Read passwords from Docker secrets
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_password_root)
MYSQL_PASSWORD=$(cat /run/secrets/db_password)

# Initialize database directory if not already created
if [ ! -d "/var/lib/mysql/mysql" ]; then
    mariadb-install-db \
        --user=mysql \
        --datadir=/var/lib/mysql \
        --skip-test-db > /dev/null
fi

# Run initial setup queries via bootstrap mode only if database doesn't exist
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    mariadbd --user=mysql --bootstrap <<EOF
USE mysql;
FLUSH PRIVILEGES;

ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

FLUSH PRIVILEGES;
EOF
fi

# Hand over process execution to MariaDB server in foreground (PID 1)
exec mariadbd --user=mysql --datadir=/var/lib/mysql