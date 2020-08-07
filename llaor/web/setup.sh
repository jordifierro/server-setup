#!/bin/bash

# Add an A Record to server ip for llaor.com and get an ssl certificate
sudo certbot certonly --manual --preferred-challenges=dns --email=jordifierromulero@gmail.com --server https://acme-v02.api.letsencrypt.org/directory --agree-tos -d "*.llaor.com" -d llaor.com

# Configure nginx
sudo cp server-setup/llaor/web/nginx.conf /etc/nginx/sites-available/llaor.com
sudo rm /etc/nginx/sites-enabled/llaor.com
sudo ln -s /etc/nginx/sites-available/llaor.com /etc/nginx/sites-enabled/
sudo systemctl reload nginx

# Deploy llaor-web on /var/www/
sudo rm -rf llaor-web
git clone https://github.com/jordifierro/llaor-web.git
cd llaor-web
echo $'NODE_PATH=src\nREACT_APP_API_HOST=http://llaor.herokuapp.com' > .env
sudo docker build -t llaor/web .
mkdir build
sudo docker run -v $(pwd)/build/:/usr/src/app/build/ -t llaor/web bash -c "npm run build"
cd ..
sudo rm -rf /var/www/llaor.com/
sudo mkdir -p /var/www/llaor.com/html
sudo chown -R $USER:$USER /var/www/llaor.com/html
sudo mv llaor-web/build/* /var/www/llaor.com/html/
