data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

variable "aws_region" {
  type    = "string"
  default = "us-east-1"
}

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

variable "rds_port" {
  default = "5432"
}

variable "ssh_cidr" {
  type    = "list"
  default = ["76.76.0.0/16"]
}

variable "vpc_cidr" {
  type        = "string"
  default     = "10.0.0.0/16"
  description = "Virtual Private Cloud Classless Inter-Domain Routing"
}

variable "public_subnet_cidrs" {
  type        = "list"
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
  description = "The cidrs the public subnet should reside in"
}

variable "private_subnet_cidrs" {
  type        = "list"
  default     = ["10.0.50.0/24", "10.0.51.0/24"]
  description = "The cidrs the private subnet should reside in"
}

## Bastion

variable "bastion_cidrs" {
  type        = "list"
  default     = ["10.0.100.0/24"]
  description = "The list of cidrs to allow ssh access from"
}

variable "bastion_instance_type" {
  type    = "string"
  default = "t2.micro"
}

variable "bastion_key_name" {
  type        = "string"
  description = "the ssh key pair to use for the bastion EC2 instance"
}

variable "bastion_ssh_user" {
  type    = "string"
  default = "ubuntu"
}

## Cluster

variable "cluster_cidrs" {
  type        = "list"
  default     = []
  description = "The cidrs the cluster should reside in"
}

variable "cluster_max_size" {
  default = 4
}

variable "cluster_min_size" {
  default = 1
}

variable "cluster_desired_capacity" {
  default = 2
}

variable "cluster_instance_type" {
  default = "t2.large"
}

variable "home" {
  default = "~"
}

variable "cluster_key_name" {
  description = "the ssh key pair to use for the EC2 instances making up the cluster"
}

variable "config_output_path" {
  default = "./"
}

## Database

variable "db_identifier" {
  default     = "pg-bench-db"
  description = "(Forces new resource) The name of the RDS instance, if omitted, Terraform will assign a random, unique identifier."
}

variable "db_name" {
  default     = "pg-bench-db"
  description = "The name of the database to create when the DB instance is created. If this parameter is not specified, no database is created in the DB instance. Note that this does not apply for Oracle or SQL Server engines. See the AWS documentation for more details on what applies for those engines."
}

variable "db_username" {
  default     = "benchtc"
  description = "(Required unless a snapshot_identifier or replicate_source_db is provided) Username for the master DB user."
}

variable "db_password" {
  description = "(Required unless a snapshot_identifier or replicate_source_db is provided) Password for the master DB user. Note that this may show up in logs, and it will be stored in the state file."
}

variable "db_subnet_cidrs" {
  type    = "list"
  default = ["10.0.101.0/24", "10.0.102.0/24"]
  description = "The cidrs the database should reside in"
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