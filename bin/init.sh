#!/bin/bash

# Exit if a command exits with a non-zero status
set -e

host_cloud="openstack"

echo "Initializing deployment directory for cloud provider $host_cloud"
# Copy config, scripts and template files to init dir
# check if file exists terraform.tfvars and ask user if he wants to overwrite it
if [ -f terraform.tfvars ]; then
    echo "File terraform.tfvars already exists. Do you want to overwrite it? (y/n)"
    read answer
    if [ "$answer" != "${answer#[Yy]}" ]; then
        cp $PWD/templates/config.tfvars.$host_cloud-template terraform.tfvars
    else
        echo "Please backup/delete terraform.tfvars file and run script again"
        exit 1
    fi
else
    cp $PWD/templates/config.tfvars.$host_cloud-template terraform.tfvars
fi

# Generate and write kubetoken
tokenID=$(openssl rand -hex 3)
tokenVal=$(openssl rand -hex 8)
token="$tokenID.$tokenVal"

# Uncomment one of the following lines depending on your OS
sed -i "" "s/your-kubeadm-token/${token}/g" $PWD/terraform.tfvars # For MacOS
# sed -i "s/your-kubeadm-token/${token}/g" $PWD/terraform.tfvars # For Linux

# Generate SSH keys
ssh-keygen -t rsa -N '' -f ssh_key
