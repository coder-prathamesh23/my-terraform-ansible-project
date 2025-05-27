Terraform + Ansible EC2 Nginx ProvisioningThis project integrates Terraform for AWS EC2 instance provisioning and Ansible for Nginx configuration, using Terraform's output IP for Ansible. It also provides GitHub setup instructions and an automation script for streamlined deployment.Project Structure.
├── README.md
├── .gitignore
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
└── ansible/
    ├── playbook.ymlc in ├── inventory.ini.tpl
   ventory)
    └── roles/
        └── nginx/
            ├── tasks/
            │   └── main.yml
            └── handlers/
                └── main.yml
Tasks and InstructionsFollow these steps to set up and run the project:1. Combine Terraform + AnsibleThis section details how to provision an EC2 instance with Terraform and then configure Nginx on it using Ansible, passing the EC2 instance's public IP address from Terraform to Ansible.Prerequisites:AWS Account: Configured with necessary IAM permissions to create EC2 instances, security groups, and key pairs.AWS CLI: Installed and configured with your AWS credentials.Terraform: Installed (version 1.0 or higher recommended).Ansible: Installed (version 2.9 or higher recommended).SSH Key Pair: An existing SSH key pair in your AWS region, or create one. Ensure the private key (.pem file) is accessible locally and has correct permissions (chmod 400 your-key.pem).Terraform (terraform/ directory):main.tf: Defines the AWS provider, EC2 instance, security group, and key pair.# terraform/main.tf

provider "aws" {
  region = var.aws_region
}

resource "aws_security_group" "nginx_sg" {
  name        = "nginx-security-group"
  description = "Allow SSH and HTTP traffic"
  vpc_id      = data.aws_vpc.default.id # Assumes a default VPC

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: For demo purposes. Restrict in production!
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nginx-sg"
  }
}

resource "aws_instance" "nginx_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name
  security_groups = [aws_security_group.nginx_sg.name]
  associate_public_ip_address = true # Ensure public IP is assigned

  tags = {
    Name = "NginxServer"
  }

  # User data to install Python for Ansible (optional, but good practice)
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y python3 python3-pip
              EOF
}

# Data source to get the latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

# Data source to get the default VPC ID
data "aws_vpc" "default" {
  default = true
}
variables.tf: Defines input variables for customization.# terraform/variables.tf

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "ap-south-1" # Example region
}

variable "instance_type" {
  description = "The EC2 instance type."
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "The name of the AWS key pair to use for SSH access."
  type        = string
  # IMPORTANT: Replace with your actual key pair name
  # default = "your-ssh-key-name"
}
outputs.tf: Defines outputs, specifically the public IP of the EC2 instance.# terraform/outputs.tf

output "ec2_public_ip" {
  description = "The public IP address of the EC2 instance."
  value       = aws_instance.nginx_server.public_ip
}
versions.tf: Specifies required Terraform and provider versions.# terraform/versions.tf

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
Ansible (ansible/ directory):playbook.yml: The main Ansible playbook to install and configure Nginx.# ansible/playbook.yml

---
- name: Configure Nginx on EC2
  hosts: all
  become: yes # Run tasks with sudo privileges
  gather_facts: yes # Gather facts about the remote host

  roles:
    - nginx
inventory.ini.tpl: A template for the Ansible inventory file. This will be populated dynamically by the shell script.# ansible/inventory.ini.tpl

[webservers]
{{ ec2_public_ip }} ansible_user=ubuntu ansible_ssh_private_key_file=../your-key.pem ansible_python_interpreter=/usr/bin/python3
Important: Replace ../your-key.pem with the correct path to your private SSH key relative to where the Ansible playbook will be run. ubuntu is the default user for Ubuntu AMIs. Adjust if using a different AMI.roles/nginx/tasks/main.yml: Tasks for the Nginx role.# ansible/roles/nginx/tasks/main.yml

---
- name: Update apt cache
  ansible.builtin.apt:
    update_cache: yes
    cache_valid_time: 3600 # Keep cache valid for 1 hour

- name: Install Nginx
  ansible.builtin.apt:
    name: nginx
    state: present

- name: Ensure Nginx service is running and enabled
  ansible.builtin.service:
    name: nginx
    state: started
    enabled: yes

- name: Copy custom Nginx index.html (optional)
  ansible.builtin.copy:
    content: "<h1>Hello from Nginx on EC2!</h1>"
    dest: /var/www/html/index.nginx-debian.html
    mode: '0644'
  notify: Restart Nginx
roles/nginx/handlers/main.yml: Handlers for the Nginx role (e.g., restarting Nginx).# ansible/roles/nginx/handlers/main.yml

---
- name: Restart Nginx
  ansible.builtin.service:
    name: nginx
    state: restarted
Deployment Steps:Navigate to Terraform directory:cd terraform/
Initialize Terraform:terraform init
Plan Terraform deployment (optional, but recommended):terraform plan
Apply Terraform deployment:terraform apply -auto-approve
This will provision the EC2 instance. Note the ec2_public_ip output.Wait for EC2 instance to be ready: It might take a few minutes for the instance to boot and for SSH to become available. You can use ssh -i your-key.pem ubuntu@<EC2_PUBLIC_IP> to test connectivity.Generate Ansible Inventory:Manually create ansible/inventory.ini using the ec2_public_ip obtained from Terraform output.# Example command to generate inventory.ini (replace with actual IP and key path)
EC2_IP=$(terraform output -raw ec2_public_ip)
sed "s/{{ ec2_public_ip }}/$EC2_IP/" ../ansible/inventory.ini.tpl > ../ansible/inventory.ini
# Make sure to adjust the key path in inventory.ini if needed
Navigate to Ansible directory:cd ../ansible/
Run Ansible Playbook:ansible-playbook -i inventory.ini playbook.yml
Ansible will connect to the EC2 instance and install Nginx.Verify Nginx: Open a web browser and navigate to http://<EC2_PUBLIC_IP>. You should see the "Hello from Nginx on EC2!" message.2. Push Project to GitHubThis section describes how to prepare your project for version control and push it to a GitHub repository.Create a New GitHub Repository:Go to GitHub and create a new empty repository (e.g., terraform-ansible-nginx).Do NOT initialize it with a README, .gitignore, or license, as we'll add our own.Separate Directories:Ensure your project structure is as described above, with terraform/ and ansible/ as separate top-level directories.Add README.md:You are currently reading this README.md file. Place it in the root of your project directory.Add .gitignore:Create a .gitignore file in the root of your project to prevent unnecessary files from being committed (like Terraform state files, temporary files, and sensitive information).# .gitignore

# Terraform
.terraform/
*.tfstate
*.tfstate.backup
.terraform.lock.hcl
crash.log
override.tf
override.tf.json
*.tfvars
*.tfvars.json
# Exclude credentials
*.pem
# Exclude sensitive files
ansible/inventory.ini # This file will be generated dynamically
Important: Ensure your private SSH key (.pem file) is not committed to the repository. It's listed in .gitignore as a safeguard.Initialize Git and Push to GitHub:# Navigate to the root of your project directory
cd /path/to/your/project

# Initialize a new Git repository
git init

# Add all files to the staging area
git add .

# Commit the changes
git commit -m "Initial project setup with Terraform, Ansible, and README"

# Link your local repository to the GitHub remote repository
# Replace <YOUR_GITHUB_USERNAME> and <YOUR_REPO_NAME> with your actual details
git remote add origin https://github.com/<YOUR_GITHUB_USERNAME>/<YOUR_REPO_NAME>.git

# Push the committed changes to GitHub
git push -u origin main
3. Automation with Shell ScriptCreate a shell script that automates the entire process: running terraform apply, waiting for the EC2 instance to be ready, and then running the Ansible playbook.deploy.sh script:Create a file named deploy.sh in the root of your project directory and make it executable (chmod +x deploy.sh).#!/bin/bash

# deploy.sh

# --- Configuration ---
# IMPORTANT: Replace with the actual path to your private SSH key
SSH_KEY_PATH="../your-key.pem"
# User for SSH connection (e.g., 'ubuntu' for Ubuntu AMIs)
SSH_USER="ubuntu"
# --- End Configuration ---

echo "--- Starting Automated Deployment ---"

# 1. Navigate to Terraform directory and apply
echo "1. Running Terraform Apply..."
cd terraform/ || { echo "Error: 'terraform/' directory not found."; exit 1; }
terraform init
if ! terraform apply -auto-approve; then
    echo "Error: Terraform apply failed."
    exit 1
fi

# Get the public IP address from Terraform output
EC2_PUBLIC_IP=$(terraform output -raw ec2_public_ip)
if [ -z "$EC2_PUBLIC_IP" ]; then
    echo "Error: Could not get EC2 public IP from Terraform output."
    exit 1
fi
echo "EC2 Instance Public IP: $EC2_PUBLIC_IP"

# Navigate back to the root directory
cd ..

# 2. Wait for EC2 instance to be ready for SSH
echo "2. Waiting for EC2 instance to be ready for SSH (up to 5 minutes)..."
SSH_READY=false
for i in {1..30}; do # Try for 30 * 10 seconds = 300 seconds (5 minutes)
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY_PATH" "$SSH_USER"@"$EC2_PUBLIC_IP" "exit"; then
        echo "SSH connection successful. EC2 is ready."
        SSH_READY=true
        break
    else
        echo "SSH not ready yet, retrying in 10 seconds... (Attempt $i/30)"
        sleep 10
    fi
done

if [ "$SSH_READY" = false ]; then
    echo "Error: EC2 instance did not become ready for SSH within the timeout."
    exit 1
fi

# 3. Generate Ansible Inventory
echo "3. Generating Ansible inventory file..."
# Create the inventory.ini file from the template
sed "s/{{ ec2_public_ip }}/$EC2_PUBLIC_IP/" ansible/inventory.ini.tpl > ansible/inventory.ini
# Ensure the SSH key path in inventory.ini is correct relative to ansible/
sed -i "s|../your-key.pem|$SSH_KEY_PATH|" ansible/inventory.ini
echo "Ansible inventory generated at ansible/inventory.ini"

# 4. Navigate to Ansible directory and run playbook
echo "4. Running Ansible Playbook..."
cd ansible/ || { echo "Error: 'ansible/' directory not found."; exit 1; }
if ! ansible-playbook -i inventory.ini playbook.yml; then
    echo "Error: Ansible playbook failed."
    exit 1
fi

echo "--- Deployment Complete! ---"
echo "Nginx should now be running on http://$EC2_PUBLIC_IP"
echo "Remember to run 'terraform destroy -auto-approve' when you are done."
How to run the automation script:Make the script executable:chmod +x deploy.sh
Run the script from the root of your project:./deploy.sh
This script will:Navigate to the terraform/ directory.Initialize and apply the Terraform configuration.Extract the public IP address of the newly provisioned EC2 instance.Wait for the EC2 instance to become reachable via SSH.Generate the ansible/inventory.ini file using the obtained IP address.Navigate to the ansible/ directory.Execute the Ansible playbook to configure Nginx.Provide a final message with the EC2 instance's IP.CleanupTo destroy the AWS resources created by Terraform:cd terraform/
terraform destroy -auto-approve
Important: Always remember to destroy your resources to avoid incurring unexpected AWS costs.
