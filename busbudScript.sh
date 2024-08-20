#!/bin/bash

# Update Packages
echo "Updating package lists..."
sudo apt-get update -y

# Install Nginx, Docker, and Docker Compose
echo "Installing Nginx, Docker, and Docker Compose..."
sudo apt-get install -y nginx docker.io
sudo apt-get install -y docker-compose

# Start and enable Nginx and Docker services
echo "Starting and enabling Nginx and Docker services..."
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl start docker
sudo systemctl enable docker

# Clone the busbud/devops-challenge-apps repository
echo "Cloning the busbud/devops-challenge-apps repository..."
https://github.com/yasith-mayura/devops-challenge-apps.git

# Create Dockerfile for App1
echo "Creating Dockerfile for api..."
mkdir -p devops-challenge-apps/api
cat <<EOF > devops-challenge-apps/api/Dockerfile
FROM node:latest
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 4000
CMD ["npm", "start"]
EOF

# Create Dockerfile for web
echo "Creating Dockerfile for web..."
mkdir -p devops-challenge-apps/web
cat <<EOF > devops-challenge-apps/web/Dockerfile
FROM node:latest
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
EOF


# Define the path to the .env file
ENV_FILE="devops-challenge-apps/.env"

# Create the .env file with the specified content
cat <<EOF > $ENV_FILE
API_PORT=4000
API_DB=postgresql://myuser:mypassword@postgres:5432/mydatabase
WEB_PORT=3000
API_HOST=http://www.api:4000
EOF

# Print a message indicating the .env file has been created
echo ".env file created at $ENV_FILE"





# Create docker-compose.yml file
echo "Creating Docker Compose file..."
cat <<EOF > devops-challenge-apps/docker-compose.yml
version: '3.8'

services:
  web:
    build: ./web
    ports:
      - "3000:3000"


    environment:
    - PORT=\${WEB_PORT}
    - API_HOST=\${API_HOST}

  postgres:
    image: postgres:15  # Use the official PostgreSQL image, version 15
    container_name: my_postgres_db  # Name of the container
    environment:
      POSTGRES_USER: myuser       # Set the PostgreSQL user
      POSTGRES_PASSWORD: mypassword  # Set the PostgreSQL password
      POSTGRES_DB: mydatabase      # Set the PostgreSQL database name
    ports:
      - "5432:5432"


  api:
    build: ./api
    ports:
      - "4000:4000"
    environment:
    - PORT=\${API_PORT}
    - DB=\${API_DB}


EOF

# Build and start Docker containers using Docker Compose
echo "Building and deploying Docker containers..."
cd devops-challenge-apps
sudo docker-compose up -d

# Nginx Host-Based Routing Configuration

# Define variables
NGINX_CONF="/etc/nginx/nginx.conf"

# Create site configuration files
cat <<EOF > $NGINX_CONF
user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
        worker_connections 768;
        # multi_accept on;
}

http {

        ##
        # Basic Settings
        ##

        sendfile on;
        tcp_nopush on;
        types_hash_max_size 2048;
        # server_tokens off;

        # server_names_hash_bucket_size 64;
        # server_name_in_redirect off;

        include /etc/nginx/mime.types;
#       default_type application/octet-stream;


        server {
           listen 80;
           server_name web.yasithmayura.me;

            location / {
		proxy_pass http://localhost:3000;
		proxy_set_header Host \$host;
		proxy_set_header X-Real-IP \$remote_addr;
		proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto \$scheme;

            }
        }
	server {
           listen 80;
           server_name api.yasithmayura.me;

            location / {
                proxy_pass http://localhost:4000;
                proxy_set_header Host \$host;
                proxy_set_header X-Real-IP \$remote_addr;
                proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto \$scheme;
            }
        }

}



EOF


# Test Nginx configuration
nginx -t

# Reload Nginx to apply changes
systemctl reload nginx

echo "Nginx setup complete. Traffic for web.example.com will be routed to port 3000 and traffic for api.example.com will be routed to port 4000."

# Test and reload Nginx configuration
echo "Testing and reloading Nginx configuration..."
sudo nginx -t && sudo systemctl reload nginx

echo "Setup complete. Applications should now be accessible at http://web.example.com and http://api.example.com."

