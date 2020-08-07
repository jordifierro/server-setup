#!/bin/bash

# Add an A Record to server ip for jordifierro.com and get an ssl certificate
sudo certbot certonly --manual --preferred-challenges=dns --email=jordifierromulero@gmail.com --server https://acme-v02.api.letsencrypt.org/directory --agree-tos -d "*.jordifierro.com" -d jordifierro.com

# Configure nginx
sudo cp server-setup/blog/nginx.conf /etc/nginx/sites-available/jordifierro.com
sudo rm /etc/nginx/sites-enabled/jordifierro.com
sudo ln -s /etc/nginx/sites-available/jordifierro.com /etc/nginx/sites-enabled/
sudo systemctl reload nginx

# Deploy llaor-web on /var/www/
sudo rm -rf jordifierro.github.io
git clone https://github.com/jordifierro/jordifierro.github.io.git
cd jordifierro.github.io
sudo mkdir -p .jekyll-cache _site
sudo docker run --rm -t --volume="$PWD:/srv/jekyll" --env JEKYLL_ENV=production jekyll/jekyll:3.8 bash -c "jekyll build --trace"
cd ..
sudo rm -rf /var/www/jordifierro.com/
sudo mkdir -p /var/www/jordifierro.com/html
sudo chown -R $USER:$USER /var/www/jordifierro.com/html
sudo mv jordifierro.github.io/_site/* /var/www/jordifierro.com/html/
