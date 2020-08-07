#!/bin/bash

sudo apt update
sudo apt -yq install haproxy
sudo cp server-setup/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg
sudo mkdir -p /etc/haproxy/certs
sudo cat /etc/letsencrypt/live/pachatary.com/fullchain.pem /etc/letsencrypt/live/pachatary.com/privkey.pem > /etc/haproxy/certs/pachatary.com.pem
sudo cat /etc/letsencrypt/live/llaor.com/fullchain.pem /etc/letsencrypt/live/llaor.com/privkey.pem > /etc/haproxy/certs/llaor.com.pem
sudo cat /etc/letsencrypt/live/jordifierro.com/fullchain.pem /etc/letsencrypt/live/jordifierro.com/privkey.pem > /etc/haproxy/certs/jordifierro.com.pem
sudo cat /etc/letsencrypt/live/taddapp.com/fullchain.pem /etc/letsencrypt/live/taddapp.com/privkey.pem > /etc/haproxy/certs/taddapp.com.pem
systemctl start haproxy
