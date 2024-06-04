# Use the official Nginx image from the Docker Hub
FROM nginx:latest

# Copy the contents of the fuconfig directory to the Nginx html directory
COPY fuconfig /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start Nginx when the container launches
CMD ["nginx", "-g", "daemon off;"]
