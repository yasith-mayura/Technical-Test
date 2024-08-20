#!/bin/bash

# Navigate to the web app directory
cd /path/to/devops-challenge-apps/web

# Pull the latest changes from the GitHub repository
echo "Pulling the latest changes from the repository..."
git pull origin main

# Rebuild and restart the web app container
echo "Rebuilding and restarting the web app container..."
sudo docker-compose build web
sudo docker-compose up -d web

# Optional: Clear any unused Docker images/containers
echo "Cleaning up unused Docker resources..."
sudo docker system prune -f

echo "Web app update complete."

