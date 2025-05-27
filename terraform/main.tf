
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.0.0-beta1"
    }
  }
}

provider "aws" {
  region = var.region

}

# New security group allowing SSH and HTTP 
#                   |
#                   V
resource "aws_security_group" "terraform-ansible-project" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP inbound traffic"

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
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
    Name = "allow_ssh_http"
  }


}



resource "aws_instance" "Terraform-Ansible-Project" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.terraform-ansible-project
  vpc_security_group_ids = [aws_security_group.terraform-ansible-project.id]
  tags = {
    Name = "TerraformAnsibleCombineProject"
  }
  user_data = <<-EOF
  #!/bin/bash
  sudo apt-get update
  sudo apt-get install -y nginx
  sudo systemctl start nginx
  sudo systemctl enable nginx
EOF

}


output "instance_public_ip" {
  description = "The public IP of the EC2 instance"
  value       = aws_instance.Terraform-Ansible-Project.public_ip
}