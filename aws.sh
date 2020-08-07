#!/bin/bash


# Create a bucket on aws s3 with name llaor, and a folder db under it
# Create an IAM user with needed permissions to read, write and delete over that bucket
# Get the credentials for that user to install & setup aws cli
sudo apt update
sudo apt install unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configurate llaor profile
source llaor/api/aws.env.list
aws configure set aws_access_key_id $LLAOR_AWS_ACCESS_KEY_ID --profile llaor
aws configure set aws_secret_access_key $LLAOR_AWS_SECRET_ACCESS_KEY --profile llaor
aws configure set region eu-west-1 --profile llaor

# Configurate pachatary profile
source pachatary/api/aws.env.list
aws configure set aws_access_key_id $PACHATARY_AWS_ACCESS_KEY_ID --profile pachatary
aws configure set aws_secret_access_key $PACHATARY_AWS_SECRET_ACCESS_KEY --profile pachatary
aws configure set region eu-west-1 --profile pachatary
