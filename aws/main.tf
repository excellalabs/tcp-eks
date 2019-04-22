#terraform {
#  backend "s3" {
#    encrypt = true
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
  cidr_block  = "${var.vpc_cidr_block}"
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
  subnets     = "${module.network.public_subnet_ids}"
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
  source = "git::https://github.com/excellaco/terraform-aws-rds.git?ref=master"

  name                  = "rds"
  namespace             = "${var.project_name}"
  environment           = "${var.environment}"
  host_name             = "${var.environment}-${var.db_identifier}"
  database_name         = "${var.db_name}"
  database_user         = "${var.db_username}"
  database_password     = "${var.db_password}"
  database_port         = "${var.db_port}"
  multi_az              = "${var.db_multi_availability_zone}"
  iops                  = "${var.db_iops}"
  allocated_storage     = "${var.db_size}"
  storage_type          = "${var.db_storage_type}"
  storage_encrypted     = "${var.db_storage_encrypted}"
  engine                = "${var.db_engine}"
  engine_version        = "${var.db_version}"
  major_engine_version  = "${var.db_major_version}"
  instance_class        = "${var.db_instance_class}"
  db_parameter_group    = "${var.db_param_family}"
  publicly_accessible   = "${var.db_publicly_accessible}"
  subnet_ids            = "${module.network.private_subnet_ids}"
  vpc_id                = "${module.vpc.id}"
  auto_minor_version_upgrade  = "${var.db_auto_minor_version_upgrade}"
  allow_major_version_upgrade = "${var.db_allow_major_version_upgrade}"
  apply_immediately           = "${var.db_apply_immediately}"
  maintenance_window          = "${var.db_maintenance_window}"
  skip_final_snapshot         = "${var.db_skip_final_snapshot}"
  copy_tags_to_snapshot       = "${var.db_copy_tags_to_snapshot}"
  backup_retention_period     = "${var.db_backup_retention_period}"
  backup_window               = "${var.db_backup_window}"
}

module "eks-cluster" {
  source = "git::https://github.com/excellaco/terraform-aws-eks.git?ref=master"

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
  cluster_cidrs     = ["${var.jenkins_cidrs}"]

  cluster_max_size = "${var.cluster_max_size}"
  cluster_min_size = "${var.cluster_min_size}"
  desired_capacity = "${var.cluster_desired_capacity}"
  cluster_key_name = "${aws_key_pair.cluster.key_name}"
  instance_type    = "${var.cluster_instance_type}"
}

# Bastion KMS key
resource "aws_key_pair" "bastion" {
  key_name   = "${var.bastion_key_name}"
  public_key = "${file(var.bastion_public_key_path)}"
}

resource "aws_kms_key" "bastion" {
  description             = "${var.project_name}-${var.environment}-bastion-kms-key"
  deletion_window_in_days = "${var.deletion_window_in_days}"
  enable_key_rotation     = "${var.enable_key_rotation}"
  tags {
    Name    = "${var.project_name}-${var.environment}-bastion-kms-key"
    Project = "${var.project_name}"
    Owner   = "${var.aws_email}"
    Created = "${timestamp()}"
    Environment = "${var.environment}"
  }
}

# Cluster KMS key
resource "aws_key_pair" "cluster" {
  key_name   = "${var.cluster_key_name}"
  public_key = "${file(var.cluster_public_key_path)}"
}

resource "aws_kms_key" "cluster" {
  description             = "${var.project_name}-${var.environment}-cluster-kms-key"
  deletion_window_in_days = "${var.deletion_window_in_days}"
  enable_key_rotation     = "${var.enable_key_rotation}"
  tags {
    Name    = "${var.project_name}-${var.environment}-cluster-kms-key"
    Project = "${var.project_name}"
    Owner   = "${var.aws_email}"
    Created = "${timestamp()}"
    Environment = "${var.environment}"
  }
}

resource "aws_kms_alias" "cluster" {
  name = "alias/${var.project_name}-${var.environment}-cluster-kms-key"
  target_key_id = "${aws_kms_key.cluster.key_id}"
}

resource "aws_s3_bucket" "terraform-state-storage-s3" {
  bucket = "${var.project_name}-terraform"
  acl    = "private"

  force_destroy = true

  versioning {
    enabled = true
  }
  tags {
    Name    = "S3 Remote Terraform State Store"
    Project = "${var.project_name}"
    Owner   = "${var.aws_email}"
    Created = "${timestamp()}"
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