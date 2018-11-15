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
  description = "The name of the cluster"
  default     = "default"
}

variable "cluster_endpoint" {
  description = "The endpoint for your EKS Kubernetes API."
  default     = ""
}

variable "cluster_security_group_id" {
  description = "Cluster security group created with necessary ingres/egress to work with the workers and provide API access to your current IP/32."
  default     = ""
}

variable "cluster_certificate_authority_data" {
  description = "Nested attribute containing certificate-authority-data for your cluster. This is the base64 encoded certificate data required to communicate with your cluster."
  default     = ""
}

variable "cluster_version" {
  description = "Kubernetes version to use for the cluster"
  default     = "1.10"
}

variable "cluster_create_timeout" {
  description = "Timeout value when creating the cluster"
  default     = "15m"
}

variable "cluster_delete_timeout" {
  description = "Timeout value when deleting the cluster"
  default     = "15m"
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

variable "instance_type" {
  description = "Size of the workers instances."
  default     = "t2.large"
}

variable "worker_group" {
  default     = "default"
  description = "The name of the workers that you consider as a group"
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

variable "desired_capacity" {
  description = "Desired worker capacity in the autoscaling group."
  default     = "1"
}

variable "max_size" {
  description = "Maximum worker capacity in the autoscaling group."
  default     = "1"
}

variable "min_size" {
  description = "Minimum worker capacity in the autoscaling group."
  default     = "1"
}

variable "key_name" {
  description = "SSH key name to be used"
}

variable "custom_userdata" {
  default     = ""
  description = "Inject extra command in the instance template to be run on boot"
}

variable "cluster_config" {
  default     = "echo '' > /etc/eks/eks.config"
  description = "Specify cluster configuration or get it from S3. Example: aws s3 cp s3://some-bucket/cluster.config /etc/eks/eks.config"
}

variable "cluster_logging" {
  default     = "[\"json-file\",\"awslogs\"]"
  description = "Adding logging option to the cluster that Docker containers can use. It is possible to add fluentd as well"
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

variable "worker_security_group_id" {
  description = "Worker security group created with necessary ingres/egress to work with the cluster."
  default     = ""
}

variable "worker_sg_ingress_from_port" {
  description = "Minimum port number from which pods will accept communication. Must be changed to a lower value if some pods in your cluster will expose a port lower than 1025 (e.g. 22, 80, or 443)."
  default     = "1025"
}

variable "config_output_path" {
  description = "Where to save the Kubectl config file (if `write_kubeconfig = true`). Should end in a forward slash `/` ."
  default     = "./"
}

variable "write_kubeconfig" {
  description = "Whether to write a Kubectl config file containing the cluster configuration. Saved to `config_output_path`."
  default     = true
}

variable "manage_aws_auth" {
  description = "Whether to write and apply the aws-auth configmap file."
  default     = false
}

variable "map_accounts" {
  description = "Additional AWS account numbers to add to the aws-auth configmap."
  type        = "list"
  default     = []
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type        = "list"
  default     = []
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type        = "list"
  default     = []
}

variable "kubeconfig_aws_authenticator_command" {
  description = "Command to use to to fetch AWS EKS credentials."
  default     = "aws-iam-authenticator"
}

variable "kubeconfig_aws_authenticator_command_args" {
  description = "Default arguments passed to the authenticator command. Defaults to [token -i $cluster_name]."
  type        = "list"
  default     = []
}

variable "kubeconfig_aws_authenticator_additional_args" {
  description = "Any additional arguments to pass to the authenticator such as the role to assume. e.g. [\"-r\", \"MyEksRole\"]."
  type        = "list"
  default     = []
}

variable "kubeconfig_aws_authenticator_env_variables" {
  description = "Environment variables that should be used when executing the authenticator. e.g. { AWS_PROFILE = \"eks\"}."
  type        = "map"
  default     = {}
}

variable "kubeconfig_name" {
  description = "Override the default name used for items kubeconfig."
  default     = ""
}

variable "pre_userdata" {
  description = "userdata to pre-append to the default userdata"
  default     = ""
}

variable "additional_userdata" {
  description = "userdata to append to the default userdata"
  default     = ""
}

variable "kubelet_extra_args" {
  description = "This string is passed directly to kubelet if set. Useful for adding labels or taints."
  default     = ""
}
