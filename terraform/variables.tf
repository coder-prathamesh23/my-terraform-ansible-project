variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1" # Optional default
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}
variable "instance_type" {
  description = "Type of EC2 instance"
  type        = string
  default     = "t2.micro"
}
variable "terraform-ansible-project" {
  description = "AWS EC2 key pair name"
  type        = string
}