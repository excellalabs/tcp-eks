variable "environment" {
  description = "The name of the environment"
}

variable "cloudwatch_prefix" {
  default     = ""
  description = "If you want to avoid cloudwatch collision or you don't want to merge all logs to one log group specify a prefix"
}

variable "cluster_name" {
  description = "The name of the cluster"
}

variable "instance_group" {
  default     = "default"
  description = "The name of the instances that you consider as a group"
}

variable "vpc_id" {
  description = "The VPC id"
}

variable "aws_ami" {
  description = "The AWS ami id to use"
}

variable "aws_email" {
  description = "the user email address"
}

variable "instance_type" {
  description = "AWS instance type to use"
}

#For more explanation see
#http://docs.aws.amazon.com/autoscaling/latest/userguide/WhatIsAutoScaling.html
variable "max_size" {
  default     = 1
  description = "Maximum size of the nodes in the cluster"
}

variable "min_size" {
  default     = 1
  description = "Minimum size of the nodes in the cluster"
}

variable "desired_capacity" {
  default     = 1
  description = "The desired capacity of the cluster"
}

variable "cloudwatch_log_file_retention" {
  description = "Number of days to retain cloudwatch log files"
  default     = "30"
}

variable "autoscaling_enabled" {
  description = "Sets whether policy and matching tags will be added to allow autoscaling."
  default     = "false"
}

variable "protect_from_scale_in" {
  description = "Prevent AWS from scaling in, so that cluster-autoscaler is solely responsible."
  default     = "false"
}

variable "suspended_processes" {
  description = "A comma delimited string of processes to to suspend. i.e. AZRebalance,HealthCheck,ReplaceUnhealthy"
  default     = ""
}

variable "target_group_arns" {
  description = "A comma delimited list of ALB target group ARNs to be associated to the ASG"
  default     = ""
}

variable "ebs_optimized" {
  description = "Sets whether to use EBS optimization on supported types"
  default     = "false"
}

variable "enable_monitoring" {
  description = "Enables/disables detailed monitoring."
  default     = "false"
}

variable "spot_price" {
  description = "Cost of spot instance."
  default     = ""
}

variable "placement_tenancy" {
  description = "The tenancy of the instance. Valid values are 'default' or 'dedicated'."
  default     = "default"
}

variable "public_ip_associated" {
  description = "Associate a public ip address with a worker."
  default     = "false"
}

variable "root_volume_size" {
  description = "Root volume size of workers instances."
  default     = "100"
}

variable "root_volume_type" {
  description = "Root volume type of workers instances, can be 'standard', 'gp2', or 'io1'"
  default     = "gp2"
}

variable "root_iops" {
  description = "The amount of provisioned IOPS. This must be set with a volume_type of 'io1'."
  default     = "0"
}

variable "iam_instance_profile_id" {
  description = "The id of the instance profile that should be used for the instances"
}

variable "private_subnet_ids" {
  type        = "list"
  description = "The list of private subnets to place the instances in"
}

variable "bastion_cidrs" {
  type        = "list"
  description = "The list of cidrs to allow ssh access from"
}

variable "load_balancers" {
  type        = "list"
  default     = []
  description = "The load balancers to couple to the instances. Only used when NOT using ALB"
}

variable "depends_id" {
  description = "Workaround to wait for the NAT gateway to finish before starting the instances"
}

variable "key_name" {
  description = "SSH key name to be used"
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
