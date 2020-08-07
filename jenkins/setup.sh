#!/bin/bash

wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update
sudo apt install openjdk-11-jdk-headless
sudo apt install jenkins
sudo systemctl enable --now jenkins

git clone git@github.com:jordifierro/server-jenkins.git
sudo chown -R jenkins:jenkins server-jenkins/
sudo rsync server-jenkins/ /var/lib/jenkins/

# Configure nginx
sudo cp server-setup/jenkins/nginx.conf /etc/nginx/sites-available/jenkins.jordifierro.com
sudo rm /etc/nginx/sites-enabled/jenkins.jordifierro.com
sudo ln -s /etc/nginx/sites-available/jenkins.jordifierro.com /etc/nginx/sites-enabled/
sudo systemctl reload nginx

# Create ssh key and add public to github and secret to jenkins
sudo su jenkins
ssh-keygen
exit
