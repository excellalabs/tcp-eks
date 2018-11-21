provider "aws" {
  region     = "${var.aws_region}"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}

module "vpc" {
  source = "modules/vpc"

  environment = "${var.environment}"
  cluster     = "${var.project_key}"
  aws_email   = "${var.aws_email}"
  cidr        = "${var.vpc_cidr}"
}

resource "aws_key_pair" "cluster" {
  key_name   = "${var.cluster_key_name}"
  public_key = "${file("${path.module}/../keys/cluster.pub")}"
}

# module "users" {
#   source = "modules/users"
# }

module "bastion-master" {
  source = "modules/bastion-master"

  vpc_id                         = "${module.vpc.id}"
  vpc_igw                        = "${module.vpc.igw}"
  environment                    = "${var.environment}"
  project_key                    = "${var.project_key}"
  aws_email                      = "${var.aws_email}"
  aws_access_key                 = "${var.aws_access_key}"
  aws_secret_key                 = "${var.aws_secret_key}"
  bastion_key_name               = "${var.bastion_key_name}"
  bastion_private_key_path       = "${var.bastion_private_key_path}"
  bastion_public_key_path        = "${var.bastion_public_key_path}"
  bastion_cidrs                  = "${var.bastion_cidrs}"
  availability_zones             = ["${data.aws_availability_zones.available.names[0]}"]
}
/*
module "jenkins-master" {
  source = "modules/jenkins-master"

  vpc_id                         = "${module.vpc.id}"
  vpc_igw                        = "${module.vpc.igw}"
  environment                    = "${var.environment}"
  project_key                    = "${var.project_key}"
  aws_email                      = "${var.aws_email}"
  aws_access_key                 = "${var.aws_access_key}"
  aws_secret_key                 = "${var.aws_secret_key}"
  jenkins_key_name               = "${var.jenkins_key_name}"
  jenkins_private_key_path       = "${var.jenkins_private_key_path}"
  jenkins_public_key_path        = "${var.jenkins_public_key_path}"
  jenkins_developer_password     = "${var.jenkins_developer_password}"
  jenkins_admin_password         = "${var.jenkins_admin_password}"
  jenkins_github_ci_user         = "${var.jenkins_github_ci_user}"
  jenkins_github_ci_token        = "${var.jenkins_github_ci_token}"
  jenkins_seedjob_repo_owner     = "${var.jenkins_seedjob_repo_owner}"
  jenkins_seedjob_repo_include   = "${var.jenkins_seedjob_repo_include}"
  jenkins_seedjob_branch_include = "${var.jenkins_seedjob_branch_include}"
  jenkins_seedjob_branch_trigger = "${var.jenkins_seedjob_branch_trigger}"
  public_subnet_cidrs            = "${var.jenkins_cidrs}"
  availability_zones             = ["${data.aws_availability_zones.available.names[0]}"]
}
*/
module "eks-cluster" {
  source = "modules/eks-cluster"

  environment          = "${var.environment}"
  vpc_id               = "${module.vpc.id}"
  vpc_igw              = "${module.vpc.igw}"
  cluster_name         = "${var.project_key}"
  cloudwatch_prefix    = "${var.project_key}/${var.environment}"
  cluster_cidrs        = ["${concat(var.bastion_cidrs, var.jenkins_cidrs)}"]
  public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidrs = ["10.0.50.0/24", "10.0.51.0/24"]
  db_subnet_cidrs      = ["10.0.101.0/24", "10.0.102.0/24"]
  db_name              = ""
  db_identifier        = "${var.db_identifier}"
  db_username          = "${var.db_username}"
  db_password          = "${var.db_password}"
  aws_email            = "${var.aws_email}"

  availability_zones = ["${data.aws_availability_zones.available.names[0]}",
    "${data.aws_availability_zones.available.names[1]}",
  ]

  max_size         = "${var.max_size}"
  min_size         = "${var.min_size}"
  desired_capacity = "${var.desired_capacity}"
  key_name         = "${aws_key_pair.cluster.key_name}"
  instance_type    = "${var.instance_type}"
}

resource "aws_s3_bucket" "terraform-state-storage-s3" {
  bucket = "${var.project_key}-terraform"
  acl    = "private"

  force_destroy = true

  versioning {
    enabled = true
  }
  tags {
    Name        = "S3 Remote Terraform State Store"
    Project     = "${var.project_key}"
    Creator     = "${var.aws_email}"
    Environment = "${var.environment}"
  }
}

resource "local_file" "terraform-file" {
    content     = <<EOF
[default]
aws_access_key_id = ${var.aws_access_key}
aws_secret_access_key = ${var.aws_secret_key}
EOF
    filename = "${path.module}/../keys/aws_credentials"
}