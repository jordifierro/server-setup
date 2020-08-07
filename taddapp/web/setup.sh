#!/bin/bash

# Add an A Record to server ip for taddapp.com and get an ssl certificate
sudo certbot certonly --manual --preferred-challenges=dns --email=jordifierromulero@gmail.com --server https://acme-v02.api.letsencrypt.org/directory --agree-tos -d "*.taddapp.com" -d taddapp.com

# Configure nginx
sudo cp server-setup/taddapp/web/nginx.conf /etc/nginx/sites-available/taddapp.com
sudo rm /etc/nginx/sites-enabled/taddapp.com
sudo ln -s /etc/nginx/sites-available/taddapp.com /etc/nginx/sites-enabled/
sudo systemctl reload nginx

# Deploy taddapp-web on /var/www/
sudo rm -rf taddapp-web
git clone git@github.com:jordifierro/taddapp-web.git
sudo rm -rf /var/www/taddapp.com/
sudo mkdir -p /var/www/taddapp.com/html
sudo chown -R $USER:$USER /var/www/taddapp.com/html
sudo mv taddapp-web/* /var/www/taddapp.com/html/
