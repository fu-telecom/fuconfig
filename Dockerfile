# Use the official Nginx image from the Docker Hub
FROM nginx:latest

# Install necessary packages
RUN apt-get update && apt-get install -y \
    php7.2-fpm \
    php7.2-mysql \
    php7.2-cli \
    php7.2-curl \
    php7.2-gd \
    php7.2-intl \
    php7.2-json \
    php7.2-mbstring \
    php7.2-xml \
    php7.2-zip \
    php7.2-soap

# Remove default server definition
RUN rm /etc/nginx/conf.d/default.conf

# Copy the contents of the fuconfig directory to the Nginx html directory
COPY ./ /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start PHP-FPM and Nginx when the container launches
CMD ["sh", "-c", "service php7.2-fpm start && nginx -g 'daemon off;'"]
