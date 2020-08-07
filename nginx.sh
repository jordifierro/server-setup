#!/bin/bash

sudo apt update
sudo apt -yq install nginx
sudo rm /etc/nginx/sites-enabled/default
sudo systemctl start nginx
