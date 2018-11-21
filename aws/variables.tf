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

## Bastion

variable "bastion_cidrs" {
  type        = "list"
  default     = ["10.0.100.0/24"]
  description = "The list of cidrs to allow ssh access from"
}

variable "bastion_instance_type" {
  default = "t2.micro"
}

variable "bastion_key_name" {
  description = "the ssh key pair to use for the bastion EC2 instance"
}

variable "bastion_private_key_path" {
  default     = "../keys/bastion"
  description = "path to ssh private key"
}

variable "bastion_public_key_path" {
  default     = "../keys/bastion.pub"
  description = "path to ssh public key"
}

## Cluster

variable "cluster_cidrs" {
  type        = "list"
  default     = []
  description = "The cidrs the cluster should reside in"
}

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

variable "cluster_key_name" {
  description = "the ssh key pair to use for the EC2 instances making up the cluster"
}

variable "db_identifier" {}

variable "db_username" {}

variable "db_password" {}

## Jenkins

variable "jenkins_cidrs" {
  type    = "list"
  default = ["10.0.103.0/24"]
}

variable "jenkins_key_name" {
  description = "ssh auth keypair name"
}

variable "jenkins_private_key_path" {
  default     = "../keys/jenkins"
  description = "path to ssh private key"
}

variable "jenkins_public_key_path" {
  default     = "../keys/jenkins.pub"
  description = "path to ssh public key"
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

variable "jenkins_seedjob_branch_include" {
  default     = "master PR-* build-*"
  description = "Branches to include from candidate repos"
}

variable "jenkins_seedjob_branch_trigger" {
  default     = "master"
  description = "Branches to automatically build (of the subset of included branches)"
}
