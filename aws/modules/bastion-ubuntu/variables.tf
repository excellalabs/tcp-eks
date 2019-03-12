data "aws_region" "current" {}

variable "aws_email" {
  description = "the user email address"
}

variable "environment" {
  description = "The name of the environment"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

variable "name" {
  description = "prefix for all created resources"
}

variable "aws_access_key" {
  default     = ""
  description = "the user aws access key"
}

variable "aws_secret_key" {
  default     = ""
  description = "the user aws secret key"
}

variable "vpc_id" {
  description = "The ID of the VPC the server should reside in"
}

variable "vpc_igw" {
  description = "The Internet Gateway ID of the VPC"
}

variable "bastion_cidrs" {
  type        = "list"
  description = "List of cidrs, for every avalibility zone you want you need one. Example: 10.0.0.0/24 and 10.0.1.0/24"
}

variable "bastion_port" {
}

variable "bastion_ssh_cidr" {
  type    = "list"
}

variable "availability_zones" {
  type        = "list"
  description = "List of avalibility zones you want. Example: us-east-1a and us-east-1b"
}

variable "bastion_key_name" {
  description = "ssh auth keypair name"
}

variable "bastion_instance_type" {
  default = "t2.micro"
  description = "instance type for bastion server"
}

variable "bastion_associate_public_ip_address" {
  default     = "true"
  description = "associate public IP address for bastion server"
}

variable "bastion_private_key_path" {
  default     = "../keys/bastion"
  description = "path to ssh private key"
}

variable "bastion_public_key_path" {
  default     = "../keys/bastion.pub"
  description = "path to ssh public key"
}