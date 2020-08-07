#!/bin/bash

sudo apt update
sudo apt -yq install docker.io
sudo systemctl enable --now docker
