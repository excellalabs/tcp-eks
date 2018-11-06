data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_ami" "eks_aws_ami" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized*"]
  }
}
/*
data "aws_ami" "eks_worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-*"]
  }
  most_recent = true
  owners      = ["602401143452"] # Amazon
}
*/
variable "aws_email" {}

variable "vpc_id" {
  description = "The ID of the VPC the cluster should reside in"
}

variable "vpc_igw" {
  description = "The Internet Gateway ID of the VPC"
}

variable "environment" {
  description = "The name of the environment"
}

variable "cluster_name" {
  default     = "default"
  description = "The name of the cluster"
}

variable "cluster_version" {
  default     = "1.10"
  description = "Kubernetes version to use for the EKS cluster"
}

variable "cluster_create_timeout" {
  description = "Timeout value when creating the EKS cluster"
  default     = "15m"
}

variable "cluster_delete_timeout" {
  description = "Timeout value when deleting the EKS cluster"
  default     = "15m"
}

variable "instance_group" {
  default     = "default"
  description = "The name of the instances that you consider as a group"
}

variable "private_subnet_cidrs" {
  type        = "list"
  description = "List of private cidrs, for every avalibility zone you want you need one. Example: 10.0.0.0/24 and 10.0.1.0/24"
}

variable "public_subnet_cidrs" {
  type        = "list"
  description = "List of public cidrs, for every avalibility zone you want you need one. Example: 10.0.0.0/24 and 10.0.1.0/24"
}

variable "bastion_cidrs" {
  type        = "list"
  description = "The list of cidrs to allow ssh access from"
}

variable "load_balancers" {
  type        = "list"
  default     = []
  description = "The load balancers to couple to the instances"
}

variable "db_subnet_cidrs" {
  type        = "list"
  description = "The cidrs the environment db should reside in"
}

variable "db_name" {
  description = "The name of the database to create when the DB instance is created. If this parameter is not specified, no database is created in the DB instance. Note that this does not apply for Oracle or SQL Server engines. See the AWS documentation for more details on what applies for those engines."
}

variable "db_username" {
  description = "(Required unless a snapshot_identifier or replicate_source_db is provided) Username for the master DB user."
}

variable "db_password" {
  description = "(Required unless a snapshot_identifier or replicate_source_db is provided) Password for the master DB user. Note that this may show up in logs, and it will be stored in the state file."
}

variable "availability_zones" {
  type        = "list"
  description = "List of avalibility zones you want. Example: us-west-2a and us-west-2b"
}

variable "max_size" {
  description = "Maximum size of the nodes in the cluster"
}

variable "min_size" {
  description = "Minimum size of the nodes in the cluster"
}

variable "desired_capacity" {
  description = "The desired capacity of the cluster"
}

variable "key_name" {
  description = "SSH key name to be used"
}

variable "instance_type" {
  description = "AWS instance type to use"
}

variable "custom_userdata" {
  default     = ""
  description = "Inject extra command in the instance template to be run on boot"
}

variable "eks_config" {
  default     = "echo '' > /etc/eks/eks.config"
  description = "Specify eks configuration or get it from S3. Example: aws s3 cp s3://some-bucket/eks.config /etc/eks/eks.config"
}

variable "eks_logging" {
  default     = "[\"json-file\",\"awslogs\"]"
  description = "Adding logging option to EKS that the Docker containers can use. It is possible to add fluentd as well"
}

variable "cloudwatch_prefix" {
  default     = ""
  description = "If you want to avoid cloudwatch collision or you don't want to merge all logs to one log group specify a prefix"
}

variable "worker_groups" {
  description = "A list of maps defining worker group configurations. See workers_group_defaults for valid keys."
  type        = "list"

  default = [{
    "name" = "default"
  }]
}

variable "worker_group_count" {
  description = "The number of maps contained within the worker_groups list."
  type        = "string"
  default     = "1"
}

variable "workers_group_defaults" {
  description = "Override default values for target groups. See workers_group_defaults_defaults in locals.tf for valid keys."
  type        = "map"
  default     = {}
}

variable "worker_security_group_id" {
  description = "If provided, all workers will be attached to this security group. If not given, a security group will be created with necessary ingres/egress to work with the EKS cluster."
  default     = ""
}

variable "worker_additional_security_group_ids" {
  description = "A list of additional security group ids to attach to worker instances."
  type        = "list"
  default     = []
}

variable "worker_sg_ingress_from_port" {
  description = "Minimum port number from which pods will accept communication. Must be changed to a lower value if some pods in your cluster will expose a port lower than 1025 (e.g. 22, 80, or 443)."
  default     = "1025"
}
