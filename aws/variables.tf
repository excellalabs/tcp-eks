data "aws_availability_zones" "available" {}

variable "aws_account_id" {
  type        = "string"
  default     = "090999229429"
  description = "AWS Account Identity"
}

variable "project_name" {
  type        = "string"
  default     = "bench-tc"
  description = "prefix for all created resources"
}

variable "environment" {
  type        = "string"
  default     = "development"
  description = "Environment i.e. production or development"
}

variable "aws_access_key" {
  type        = "string"
  default     = ""
  description = "the user aws access key"
}

variable "aws_secret_key" {
  type        = "string"
  default     = ""
  description = "the user aws secret key"
}

variable "aws_email" {
  type        = "string"
  default     = ""
  description = "the user email address"
}

variable "vpc_cidr" {
  type        = "string"
  default     = "10.0.0.0/16"
  description = "Virtual Private Cloud Classless Inter-Domain Routing"
}

## Bastion

variable "bastion_cidrs" {
  type        = "list"
  default     = ["10.0.100.0/24"]
  description = "The list of cidrs to allow ssh access from"
}

variable "bastion_instance_type" {
  type        = "string"
  default = "t2.micro"
}

variable "bastion_key_name" {
  type        = "string"
  description = "the ssh key pair to use for the bastion EC2 instance"
}

variable "bastion_private_key_path" {
  type        = "string"
  default     = "../keys/bench-tc-bastion"
  description = "path to ssh private key"
}

variable "bastion_public_key_path" {
  type        = "string"
  default     = "../keys/bench-tc-bastion.pub"
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

variable "db_identifier" {
  default     = "pg-bench-db"
  description = "database name"
}

variable "db_username" {
  default     = "benchtc"
  description = "database username"
}

variable "db_password" {
  description = "password for database username"
}

## Jenkins

variable "jenkins_cidrs" {
  type    = "list"
  default = ["10.0.103.0/24"]
  description = "The cidrs that jenkins should reside in"
}

variable "jenkins_key_name" {
  description = "ssh auth keypair name"
}

variable "jenkins_private_key_path" {
  default     = "../keys/bench-tc-jenkins"
  description = "path to ssh private key"
}

variable "jenkins_public_key_path" {
  default     = "../keys/bench-tc-jenkins.pub"
  description = "path to ssh public key"
}

variable "jenkins_developer_password" {
  description = "jenkins password for dev user"
}

variable "jenkins_admin_password" {
  description = "jenkins password for admin user"
}

variable "github_user" {
  description = "The user jenkins should use for github scm checkouts"
}

variable "github_token" {
  description = "GitHub api token for the 'github_user'"
}

variable "github_repo_owner" {
  description = "The github user account that *owns* the repos for which pipelines should be instantiated"
}

variable "github_repo_include" {
  description = "Repos to include from github owner account"
}

variable "github_branch_include" {
  default     = "master PR-* build-*"
  description = "Branches to include from candidate repos"
}

variable "github_branch_trigger" {
  default     = "master"
  description = "Branches to automatically build (of the subset of included branches)"
}