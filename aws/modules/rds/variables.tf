variable "db_name" {
  description = "The name of the database to create when the DB instance is created. If this parameter is not specified, no database is created in the DB instance. Note that this does not apply for Oracle or SQL Server engines. See the AWS documentation for more details on what applies for those engines."
}

variable "db_identifier" {
  description = "(Forces new resource) The name of the RDS instance, if omitted, Terraform will assign a random, unique identifier."
}

variable "db_username" {
  description = "(Required unless a snapshot_identifier or replicate_source_db is provided) Username for the master DB user."
}

variable "db_password" {
  description = "(Required unless a snapshot_identifier or replicate_source_db is provided) Password for the master DB user. Note that this may show up in logs, and it will be stored in the state file."
}

variable "db_instance_class" {
  description = "(Required) The instance type of the RDS instance."
  default     = "db.t2.medium"
}

variable "db_size" {
  description = "allocated_storage (Required unless a snapshot_identifier or replicate_source_db is provided) The allocated storage in gibibytes."
  default     = 20
}

variable "db_engine" {
  description = "(Required unless a snapshot_identifier or replicate_source_db is provided) The database engine to use."
  default     = "postgres"
}

variable "db_storage_type" {
  description = "(Optional) One of standard (magnetic), gp2 (general purpose SSD), or io1 (provisioned IOPS SSD). The default is io1 if iops is specified, standard if not. Note that this behaviour is different from the AWS web console, where the default is gp2."
  default     = "gp2"
}

variable "db_storage_encrypted" {
  description = "(Optional) Specifies whether the DB instance is encrypted. Note that if you are creating a cross-region read replica this field is ignored and you should instead declare kms_key_id with a valid ARN. The default is false if not specified."
  default     = true
}

variable "db_maintenance_window" {
  description = "(Optional) The window to perform maintenance in. Syntax: ddd:hh24:mi-ddd:hh24:mi. Eg: Sun:00:00-Sun:03:00."

  # SUN 12:30AM-01:30AM ET
  default = "Sun:04:30-Sun:05:30"
}

variable "db_backup_retention_period" {
  description = "(Optional) The days to retain backups for. Must be 1 or greater to be a source for a Read Replica."
  default     = 0
}

variable "db_backup_window" {
  description = "(Optional) The daily time range (in UTC) during which automated backups are created if they are enabled. Example: 09:46-10:16. Must not overlap with maintenance_window."

  # 12:00AM-12:30AM ET
  default = "04:00-04:30"
}

variable db_iops {
  description = "(Optional) The amount of provisioned IOPS. Setting this implies a storage_type of io1."
  default     = 0
}

variable "db_multi_availability_zone" {
  description = "(Optional) Specifies if the RDS instance is multi availability zone"
  default     = true
}

variable "db_publicly_accessible" {
  description = "(Optional) Bool to control if instance is publicly accessible. Default is false."
  default     = false
}

variable "db_auto_minor_version_upgrade" {
  description = "(Optional) Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window. Defaults to true."
  default     = true
}

variable "db_skip_final_snapshot" {
  description = "(Optional) Determines whether a final DB snapshot is created before the DB instance is deleted. If true is specified, no DBSnapshot is created. If false is specified, a DB snapshot is created before the DB instance is deleted, using the value from final_snapshot_identifier. Default is false."
  default     = true
}

variable "db_copy_tags_to_snapshot" {
  description = "(Optional, boolean) On delete, copy all Instance tags to the final snapshot (if final_snapshot_identifier is specified). Default is false."
  default     = false
}

# PostgreSQL
variable "db_param_family" {
  description = "(Optional) Name of the DB parameter group to associate."
  default     = "postgres9.6"
}

variable "db_version" {
  description = "engine_version (Optional) The engine version to use. If auto_minor_version_upgrade is enabled, you can provide a prefix of the version"
  default     = "9.6.6"
}

variable "db_port" {
  description = "(Optional) The port on which the DB accepts connections."
  default     = 5432
}

# CloudWatch for Database
variable "alarm_cpu_threshold" {
  description = "The level at which to alert about lack of CPU threshold (%)"
  default     = "75"
}

variable "alarm_disk_queue_threshold" {
  description = "The level at which to alert about lack of disk queue depth"
  default     = "10"
}

variable "alarm_cpu_credit_balance_threshold" {
  description = "The level at which to alert about lack of CPU credit balance (%)"
  default     = "30"
}

variable "db_free_memory_alert_level" {
  description = "The level at which to alert about lack of freeable memory (MB)"
  default     = 128
}

variable "db_free_storage_alert_level" {
  description = "The level at which to alert about lack of free storage (GB)"
  default     = 5
}

data "aws_caller_identity" "current" {}

variable "aws_email" {}

variable "aws_region" {}

variable "environment" {}

variable "project_key" {}

variable "vpc_id" {}

variable "availability_zones" {
  type        = "list"
  description = "List of avalibility zones you want. Example: us-west-2a and us-west-2b"
}

variable "db_access_cidrs" {
  type        = "list"
  description = "List of private cidrs, for every avalibility zone you want you need one"
}

variable "db_subnet_cidrs" {
  type        = "list"
  description = "List of private cidrs, for every avalibility zone you want you need one"
}
