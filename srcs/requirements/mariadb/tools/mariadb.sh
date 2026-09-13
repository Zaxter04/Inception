#!/bin/bash
set -e

MYSQL_ROOT_PASSWORD="$(cat /run/secrets/db_password_root)"
MYSQL_PASSWORD="$(cat /run/secrets/db_password)"

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB database..."

    mariadb-install-db \
        --user=mysql \
        --datadir=/var/lib/mysql \
        --skip-test-db

    mariadbd \
        --user=mysql \
        --datadir=/var/lib/mysql \
        --bootstrap <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

FLUSH PRIVILEGES;
EOF
fi

exec mariadbd \
    --user=mysql \
    --datadir=/var/lib/mysql
