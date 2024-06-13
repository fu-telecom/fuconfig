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
    kubernetes-client \
    tftpd-hpa \
    git

# Remove default server definition
RUN rm /etc/nginx/conf.d/default.conf

# Copy the contents of the fuconfig directory to the Nginx html directory
COPY ./fuconfig /usr/share/nginx/html
COPY ./default /usr/share/nginx/default
COPY ./asterisk_scripts /asterisk_scripts

# Clone the tftproot directory from the GitHub repository
RUN git clone --depth 1 https://github.com/fu-telecom/fuconfig.git /tmp/fuconfig && mv /tmp/fuconfig/tftproot/* /tftproot && rm -rf /tmp/fuconfig

# Debugging: Verify contents of /tftproot after cloning
RUN ls -la /tftproot

# Copy the startup script
COPY ./startupscript.sh /docker-entrypoint.d/35-startupscript.sh
RUN chmod +x /docker-entrypoint.d/35-startupscript.sh

# Set up kubeconfig for www-data
RUN mkdir -p /home/www-data/.kube && \
    chown -R www-data:www-data /home/www-data/.kube
COPY --chown=www-data:www-data ./kubeconfig /home/www-data/.kube/config

# Change ownership and permissions
RUN chown -R www-data:www-data /usr/share/nginx/html
RUN chown -R www-data:www-data /asterisk_scripts
RUN chown -R www-data:www-data /usr/share/nginx/default
RUN chown -R www-data:www-data /tftproot
RUN chmod -R 755 /usr/share/nginx/html
RUN chmod -R 755 /usr/share/nginx/default
RUN chmod -R 755 /tftproot

# Debugging: Verify contents of /tftproot after permissions
RUN ls -la /tftproot

# Expose ports 80 and 69 (UDP)
EXPOSE 80 69/udp

# Start PHP-FPM, TFTP server, and Nginx when the container launches
CMD ["sh", "-c", "service php8.2-fpm start && service tftpd-hpa start && /docker-entrypoint.d/35-startupscript.sh && nginx -g 'daemon off;'"]
