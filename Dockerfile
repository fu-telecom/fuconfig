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
    systemd

# Remove default server definition
RUN rm /etc/nginx/conf.d/default.conf
RUN systemctl enable php8.2-fpm

# Copy the contents of the fuconfig directory to the Nginx html directory
ADD ./fuconfig /usr/share/nginx/html
ADD ./default /usr/share/nginx/default
ADD ./asterisk_scripts /asterisk_scripts

# Install php-k8s library manually
RUN git clone https://github.com/maclof/kubernetes-client.git /usr/share/nginx/html/vendor/maclof/kubernetes-client

# Install Illuminate Support package manually
RUN git clone https://github.com/illuminate/support.git /usr/share/nginx/html/vendor/illuminate/support

# Copy the startup script and make it executable
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
