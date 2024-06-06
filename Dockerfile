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
    systemd

# Remove default server definition
RUN rm /etc/nginx/conf.d/default.conf
RUN systemctl enable php8.2-fpm

# Copy the contents of the fuconfig directory to the Nginx html directory
COPY ./ /usr/share/nginx/html
COPY ./startupscript.sh /docker-entrypoint.d

# Expose port 80
EXPOSE 80

# Start PHP-FPM and Nginx when the container launches
CMD ["sh", "-c", "nginx -g 'daemon off;'"]
