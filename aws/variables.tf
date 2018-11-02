data "aws_availability_zones" "available" {}

variable "project_key" {
  description = "prefix for all created resources"
}

variable "environment" {
  description = "Environment i.e. production or development"
}

variable "aws_access_key" {
  default     = ""
  description = "the user aws access key"
}

variable "aws_secret_key" {
  default     = ""
  description = "the user aws secret key"
}

variable "aws_email" {
  description = "the user email address"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "bastion_instance_type" {
  default = "t2.micro"
}

## ECS Cluster

variable "max_size" {
  default = 4
}

variable "min_size" {
  default = 1
}

variable "desired_capacity" {
  default = 2
}

variable "instance_type" {
  default = "t2.large"
}

variable "aws_region" {}

variable "home" {
  default = "~"
}

variable "ecs_key_name" {
  description = "the ssh key pair to use for the EC2 instances making up the ECS cluster"
}

variable "db_username" {}

variable "db_password" {}

## Jenkins

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

variable "jenkins_key_name" {
  description = "ssh auth keypair name"
}

variable "vpc-fullcidr" {
  default     = "172.27.0.0/16"
  description = "the vpc cdir"
}

variable "Subnet-Public-AzA-CIDR" {
  default     = "172.27.0.0/24"
  description = "the cidr of the subnet"
}

variable "Subnet-Private-AzA-CIDR" {
  default     = "172.27.3.0/24"
  description = "the cidr of the subnet"
}

variable "jenkins_private_key_path" {
  default     = "../keys/jenkins"
  description = "path to ssh private key"
}

variable "jenkins_public_key_path" {
  default     = "../keys/jenkins.pub"
  description = "path to ssh public key"
}

variable "DnsZoneName" {
  default     = "jenkins_master"
  description = "Jenkins DNS name"
}

variable "jenkins_email" {
  default     = "null@null.null"
  description = "email for dev and admin users"
}

variable "jenkins_developer_password" {
  description = "jenkins password for dev user"
}

variable "jenkins_admin_password" {
  description = "jenkins password for admin user"
}

variable "jenkins_github_ci_user" {
  description = "The user jenkins should use for github scm checkouts"
}

variable "jenkins_github_ci_token" {
  description = "GitHub api token for the 'jenkins_github_ci_user'"
}

variable "jenkins_seedjob_repo_owner" {
  description = "The github user account that *owns* the repos for which pipelines should be instantiated"
}

variable "jenkins_seedjob_repo_include" {
  description = "Repos to include from github owner account"
}

variable "jenkins_seedjob_repo_exclude" {
  default     = ""
  description = "Exceptions for the jenkins_seedjob_repo_include pattern"
}

variable "jenkins_seedjob_branch_include" {
  default     = "master PR-* build-*"
  description = "Branches to include from candidate repos"
}

variable "jenkins_seedjob_branch_exclude" {
  default     = ""
  description = "Exceptions for the jenkins_seedjob_branch_include pattern"
}

variable "jenkins_seedjob_branch_trigger" {
  default     = "master"
  description = "Branches to automatically build (of the subset of included branches)"
}
