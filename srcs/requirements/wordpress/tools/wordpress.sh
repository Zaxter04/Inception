#!/bin/bash
set -e

# Read passwords directly from secret files
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_PASSWORD=$(cat /run/secrets/wp_password)

# Wait for MariaDB service
while ! mariadb-admin ping -h"$MYSQL_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent; do
    echo "Waiting for MariaDB..."
    sleep 2
done

# Install WP-CLI if missing
if [ ! -f /usr/local/bin/wp ]; then
    wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
fi

# Download & Install WordPress
if [ ! -f /var/www/html/wp-config.php ]; then
    wp core download --allow-root --path='/var/www/html' || true

    wp config create \
        --allow-root \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="$MYSQL_HOSTNAME" \
        --path='/var/www/html'

    wp core install \
        --allow-root \
        --url="$DOMAIN_NAME" \
        --title="$SITE_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --path='/var/www/html'

    wp user create \
        "$WP_USER" "$WP_EMAIL" \
        --role=author \
        --user_pass="$WP_PASSWORD" \
        --allow-root \
        --path='/var/www/html'
fi

chown -R www-data:www-data /var/www/html

# Start PHP-FPM in foreground
exec php-fpm8.2 -F