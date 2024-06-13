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
ADD ./fuconfig /usr/share/nginx/html
ADD ./default /usr/share/nginx/default
COPY ./startupscript.sh /docker-entrypoint.d/35-startupscript.sh
RUN chmod +x /docker-entrypoint.d/35-startupscript.sh

# Expose port 80
EXPOSE 80

# Start PHP-FPM and Nginx when the container launches
CMD ["sh", "-c", "/docker-entrypoint.d/35-startupscript.sh && nginx -g 'daemon off;'"]