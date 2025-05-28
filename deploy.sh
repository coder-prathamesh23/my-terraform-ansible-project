#!/bin/bash

set -e  # Exit immediately if any command fails

# Step 1: Run Terraform
cd terraform
echo "🔧 Initializing and applying Terraform..."
terraform init
terraform validate
terraform plan -var-file="terraform.tfvars" 
terraform apply -var-file="terraform.tfvars" -auto-approve

# Step 2: Wait for EC2 provisioning
echo "⏳ Waiting for EC2 instance to be provisioned..."
sleep 30

# Step 3: Fetch EC2 public IP
IP_ADDRESS=$(terraform output -raw instance_public_ip)
echo "🌐 EC2 Public IP: $IP_ADDRESS"

# Step 4: Generate Ansible inventory dynamically
cd ../ansible
echo "📄 Creating Ansible inventory file..."
echo "[webservers]" > inventory
echo "$IP_ADDRESS ansible_user=ubuntu ansible_ssh_private_key_file=/home/prem/ec2keys/new-key-pair.pem" >> inventory

# Step 5: Set correct permissions on the key
chmod 400 /home/prem/ec2keys/new-key-pair.pem

# Step 6: Run Ansible playbook
echo "🚀 Running Ansible playbook..."
ansible-playbook -i inventory playbook.yml

echo "✅ Deployment completed successfully!"
