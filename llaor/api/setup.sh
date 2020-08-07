#!/bin/bash

# Copy docker nginx file to host but not enable it
sudo mdkir -p /etc/nginx/sites-available/api.llaor.com
sudo cp server-setup/llaor/api/nginx.conf /etc/nginx/sites-available/api.llaor.com/nginx.conf
sudo sed 's/llaor-api/llaor-api-01/g' /etc/nginx/sites-available/api.llaor.com/nginx.conf > /etc/nginx/sites-available/api.llaor.com/nginx-01.conf
sudo sed 's/llaor-api/llaor-api-02/g' /etc/nginx/sites-available/api.llaor.com/nginx.conf > /etc/nginx/sites-available/api.llaor.com/nginx-02.conf

# Deploy llaor-web on /var/www/
sudo rm -rf llaor-api
git clone https://github.com/jordifierro/llaor-api.git
cp server-setup/llaor/api/env.list llaor-api/
cd llaor-api

sudo docker build -t llaor/api .

sudo docker volume create llaor-statics-01
sudo docker run -d --restart=always --env-file env.list --net llaor-net -v llaor-statics-01:/code/llaor/staticfiles --name llaor-api-01 -t llaor/api
sudo docker run --name llaor-nginx-01 -v llaor-statics-01:/usr/share/nginx/html/static:ro -v /etc/nginx/sites-available/api.llaor.com/nginx-01.conf:/etc/nginx/nginx.conf:ro -p 127.0.0.2:80:80 --net llaor-net --restart=always -d nginx


sudo docker volume create llaor-statics-02
sudo docker run -d --restart=always --env-file env.list --net llaor-net -v llaor-statics-02:/code/llaor/staticfiles --name llaor-api-02 -t llaor/api
sudo docker run --name llaor-nginx-02 -v llaor-statics-02:/usr/share/nginx/html/static:ro -v /etc/nginx/sites-available/api.llaor.com/nginx-02.conf:/etc/nginx/nginx.conf:ro -p 127.0.0.3:80:80 --net llaor-net --restart=always -d nginx
