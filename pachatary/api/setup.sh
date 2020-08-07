#!/bin/bash

# Add an A Record to server ip for pachatary.com and get an ssl certificate
sudo certbot certonly --manual --preferred-challenges=dns --email=jordifierromulero@gmail.com --server https://acme-v02.api.letsencrypt.org/directory --agree-tos -d "*.pachatary.com" -d pachatary.com

# Copy docker nginx file to host but not enable it
sudo mdkir -p /etc/nginx/sites-available/api.pachatary.com
sudo cp server-setup/pachatary/api/nginx.conf /etc/nginx/sites-available/api.pachatary.com/nginx.conf
sudo sed 's/pachatary-api/pachatary-api-01/g' /etc/nginx/sites-available/api.pachatary.com/nginx.conf > /etc/nginx/sites-available/api.pachatary.com/nginx-01.conf
sudo sed 's/pachatary-api/pachatary-api-02/g' /etc/nginx/sites-available/api.pachatary.com/nginx.conf > /etc/nginx/sites-available/api.pachatary.com/nginx-02.conf

# Deploy pachatary-api
sudo rm -rf pachatary-api
git clone https://github.com/jordifierro/pachatary-api.git
cp server-setup/pachatary/api/env.list pachatary-api/
cd pachatary-api
sudo docker build -t pachatary/api .

sudo docker volume create pachatary-statics-01
sudo docker run -d --restart=always --env-file env.list --net pachatary-net -v pachatary-statics-01:/code/pachatary/staticfiles --name pachatary-api-01 -e INTERNAL_IP=127.0.1.1 -t pachatary/api
sudo docker run --name pachatary-nginx-01 -v pachatary-statics-01:/usr/share/nginx/html/static:ro -v /etc/nginx/sites-available/api.pachatary.com/nginx-01.conf:/etc/nginx/nginx.conf:ro -p 127.0.1.1:80:80 --net pachatary-net --restart=always -d nginx


sudo docker volume create pachatary-statics-02
sudo docker run -d --restart=always --env-file env.list --net pachatary-net -v pachatary-statics-02:/code/pachatary/staticfiles --name pachatary-api-02  -e INTERNAL_IP=127.0.1.2 -t pachatary/api
sudo docker run --name pachatary-nginx-02 -v pachatary-statics-02:/usr/share/nginx/html/static:ro -v /etc/nginx/sites-available/api.pachatary.com/nginx-02.conf:/etc/nginx/nginx.conf:ro -p 127.0.1.2:80:80 --net pachatary-net --restart=always -d nginx
