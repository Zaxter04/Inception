#!/bin/bash

set -e

MYSQL_PASSWORD="$(cat /run/secrets/db_password)"
WP_ADMIN_PASSWORD="$(cat /run/secrets/wp_admin_password)"
WP_PASSWORD="$(cat /run/secrets/wp_password)"

echo "Waiting for MariaDB..."

until mariadb-admin ping \
    -h"$MYSQL_HOSTNAME" \
    -u"$MYSQL_USER" \
    -p"$MYSQL_PASSWORD" \
    --silent
do
    echo "MariaDB is not ready..."
    sleep 2
done

echo "MariaDB is ready."

cd /var/www/html

if [ ! -f wp-config.php ]; then

    echo "Downloading WordPress..."

    wp core download \
        --allow-root \
        --path=/var/www/html

    echo "Creating wp-config.php..."

    wp config create \
        --allow-root \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="$MYSQL_HOSTNAME" \
        --path=/var/www/html

    echo "Installing WordPress..."

    wp core install \
        --allow-root \
        --url="$DOMAIN_NAME" \
        --title="$SITE_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --path=/var/www/html

    echo "Creating WordPress user..."

    wp user create \
        "$WP_USER" \
        "$WP_EMAIL" \
        --role=author \
        --user_pass="$WP_PASSWORD" \
        --allow-root \
        --path=/var/www/html

fi

chown -R www-data:www-data /var/www/html

echo "Starting PHP-FPM..."

exec php-fpm8.2 -F