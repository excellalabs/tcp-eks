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
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

variable "project_key" {
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
  description = "The ID of the VPC the cluster should reside in"
}

variable "vpc_igw" {
  description = "The Internet Gateway ID of the VPC"
}

variable "public_subnet_cidrs" {
  type        = "list"
  description = "List of public cidrs, for every avalibility zone you want you need one. Example: 10.0.0.0/24 and 10.0.1.0/24"
}

variable "availability_zones" {
  type        = "list"
  description = "List of avalibility zones you want. Example: us-west-2a and us-west-2b"
}

variable "jenkins_key_name" {
  description = "ssh auth keypair name"
}

variable "jenkins_instance_type" {
  default = "m5.xlarge"
  description = "instance type for jenkins server"
}

variable "jenkins_root_volume_type" {
  default = "gp2"
  description = "volume type for jenkins server"
}

variable "jenkins_root_volume_size" {
  default = "100"
  description = "volume size for jenkins server"
}

variable "jenkins_root_volume_delete_on_termination" {
  default     = "true"
  description = "delete root block device volume on termination for jenkins server"
}

variable "jenkins_associate_public_ip_address" {
  default     = "true"
  description = "associate public IP address for jenkins server"
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
