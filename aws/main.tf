#terraform {
#  backend "s3" {
#  }
#}

provider "aws" {
  region     = "${var.aws_region}"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}

module "vpc" {
  source = "git::https://github.com/excellaco/terraform-aws-vpc.git?ref=master"

  name        = "${var.project_name}"
  environment = "${var.environment}"
  aws_email   = "${var.aws_email}"
  cidr        = "${var.vpc_cidr}"
}

module "network" {
  source = "git::https://github.com/excellaco/terraform-aws-network.git?ref=master"

  name        = "${var.project_name}"
  environment = "${var.environment}"
  aws_email   = "${var.aws_email}"
  vpc_id      = "${module.vpc.id}"
  vpc_igw     = "${module.vpc.igw}"
  depends_id  = ""

  public_subnet_cidrs  = "${var.public_subnet_cidrs}"
  private_subnet_cidrs = "${var.private_subnet_cidrs}"
  availability_zones   = ["${data.aws_availability_zones.available.names[0]}",
    "${data.aws_availability_zones.available.names[1]}"]
}

module "bastion" {
  source = "git::https://github.com/excellaco/terraform-aws-ec2-bastion-server.git?ref=master"

  name        = "bastion"
  namespace   = "${var.project_name}"
  environment = "${var.environment}"
  port        = "${var.rds_port}"
  vpc_id      = "${module.vpc.id}"
  key_name    = "${var.bastion_key_name}"
  subnets     = "${var.bastion_cidrs}"
  ssh_user    = "${var.bastion_ssh_user}"
  security_groups = []
  allowed_cidr_blocks = "${var.ssh_cidr}"
}

module "jenkins" {
  source = "git::https://github.com/excellaco/terraform-aws-ec2-jenkins-server.git?ref=master"

  vpc_id                     = "${module.vpc.id}"
  vpc_igw                    = "${module.vpc.igw}"
  environment                = "${var.environment}"
  name                       = "${var.project_name}"
  aws_email                  = "${var.aws_email}"
  aws_access_key             = "${var.aws_access_key}"
  aws_secret_key             = "${var.aws_secret_key}"
  jenkins_key_name           = "${var.jenkins_key_name}"
  jenkins_private_key_path   = "${var.jenkins_private_key_path}"
  jenkins_public_key_path    = "${var.jenkins_public_key_path}"
  jenkins_developer_password = "${var.jenkins_developer_password}"
  jenkins_admin_password     = "${var.jenkins_admin_password}"
  github_user                = "${var.github_user}"
  github_token               = "${var.github_token}"
  github_repo_owner          = "${var.github_repo_owner}"
  github_repo_include        = "${var.github_repo_include}"
  github_branch_include      = "${var.github_branch_include}"
  github_branch_trigger      = "${var.github_branch_trigger}"
  public_subnet_cidrs        = "${var.jenkins_cidrs}"
  availability_zones         = ["${data.aws_availability_zones.available.names[0]}"]
}

module "rds" {
  source = "modules/rds"

  name               = "${var.project_name}"
  environment        = "${var.environment}"
  aws_email          = "${var.aws_email}"
  aws_region         = "${data.aws_region.current.name}"
  vpc_id             = "${module.vpc.id}"
  db_subnet_cidrs    = "${var.db_subnet_cidrs}"
  db_access_cidrs    = ["${concat(var.cluster_cidrs, var.private_subnet_cidrs)}"]
  db_name            = "${var.db_name}"
  db_identifier      = "${var.environment}-${var.db_identifier}"
  db_username        = "${var.db_username}"
  db_password        = "${var.db_password}"

  availability_zones = ["${data.aws_availability_zones.available.names[0]}",
    "${data.aws_availability_zones.available.names[1]}"
  ]
}

module "eks-cluster" {
  source = "modules/eks-cluster"

  name         = "${var.project_name}"
  environment  = "${var.environment}"
  aws_email    = "${var.aws_email}"
  aws_region   = "${var.aws_region}"
  cluster_name = "${var.project_name}-${var.environment}-cluster"
  vpc_id       = "${module.vpc.id}"

  config_output_path = "${var.config_output_path}"
  cloudwatch_prefix  = "${var.project_name}/${var.environment}"
  private_subnet    = "${module.network.private_subnet_ids}"
  public_subnet     = "${module.network.public_subnet_ids}"
  cluster_cidrs     = ["${concat(var.bastion_cidrs, var.jenkins_cidrs)}"]

  cluster_max_size = "${var.cluster_max_size}"
  cluster_min_size = "${var.cluster_min_size}"
  desired_capacity = "${var.cluster_desired_capacity}"
  cluster_key_name = "${aws_key_pair.cluster.key_name}"
  instance_type    = "${var.cluster_instance_type}"
}

# Cluster KMS key
resource "aws_key_pair" "cluster" {
  key_name   = "${var.cluster_key_name}"
  public_key = "${file("${path.module}/../keys/${var.cluster_key_name}.pub")}"
}

resource "aws_s3_bucket" "terraform-state-storage-s3" {
  bucket = "${var.project_name}-terraform"
  acl    = "private"

  force_destroy = true

  versioning {
    enabled = true
  }
  tags {
    Name        = "S3 Remote Terraform State Store"
    Project     = "${var.project_name}"
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
