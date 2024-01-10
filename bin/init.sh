#!/bin/bash

# Exit if a command exits with a non-zero status
set -e

host_cloud="openstack"

echo "Initializing deployment directory for cloud provider $host_cloud"
path=$PWD
echo $path

# Generate and write kubetoken
tokenID=$(openssl rand -hex 3)
tokenVal=$(openssl rand -hex 8)
token="$tokenID.$tokenVal"

sed -i "" "s/your-kubeadm-token/${token}/g" $path/terraform.tfvars # For MacOS
# sed -i "s/your-kubeadm-token/${token}/g" $path/terraform.tfvars # For Linux

# Generate SSH keys
ssh-keygen -t rsa -N '' -f ssh_key
