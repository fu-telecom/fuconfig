# Use the official Nginx image from the Docker Hub
FROM nginx:latest

# Install necessary packages
RUN apt-get update && apt-get install -y \
    php-fpm \
    php-mysql \
    php-cli \
    php-curl \
    php-gd \
    php-intl \
    php-json \
    php-mbstring \
    php-xml \
    php-zip \
    php-soap \
    git \
    unzip \
    systemd

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Remove default server definition
RUN rm /etc/nginx/conf.d/default.conf
RUN systemctl enable php8.2-fpm

# Set the working directory
WORKDIR /usr/share/nginx/html

# Copy the composer.json file to the container
COPY composer.json /usr/share/nginx/html/composer.json

# Install PHP dependencies
RUN composer install

# Copy the rest of the project files to the container
ADD ./fuconfig /usr/share/nginx/html
ADD ./default /usr/share/nginx/default
ADD ./asterisk_scripts /asterisk_scripts
COPY ./startupscript.sh /docker-entrypoint.d/35-startupscript.sh
RUN chmod +x /docker-entrypoint.d/35-startupscript.sh

# Change ownership and permissions
RUN chown -R www-data:www-data /usr/share/nginx/html
RUN chown -R www-data:www-data /asterisk_scripts
RUN chown -R www-data:www-data /usr/share/nginx/default
RUN chmod -R 755 /usr/share/nginx/html
RUN chmod -R 755 /usr/share/nginx/default

# Expose port 80
EXPOSE 80

# Start PHP-FPM and Nginx when the container launches
CMD ["sh", "-c", "/docker-entrypoint.d/35-startupscript.sh && nginx -g 'daemon off;'"]
