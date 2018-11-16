# Database Parameter Group and Instance

resource "aws_db_parameter_group" "db_parameter" {
  name        = "${var.environment}-${var.db_engine}-db-parameter-group"
  family      = "${var.db_param_family}"
  description = "${var.db_engine} Paramater Group"
  tags {
    Name        = "${lower(var.db_identifier)}-parameter-group"
    Project     = "${var.project_key}"
    Creator     = "${var.aws_email}"
    Environment = "${var.environment}"
  }
}

resource "aws_kms_key" "rds_encryption_key" {
  description             = "KMS key for RDS"
  deletion_window_in_days = 7
  enable_key_rotation     = false
  tags {
    Name        = "${lower(var.db_identifier)}-encryption-key"
    Project     = "${var.project_key}"
    Creator     = "${var.aws_email}"
    Environment = "${var.environment}"
  }
}

resource "aws_kms_alias" "rds_encryption_key_alias" {
  name          = "alias/${lower(var.db_identifier)}"
  target_key_id = "${aws_kms_key.rds_encryption_key.key_id}"
}

resource "aws_db_instance" "sql_database" {
  allocated_storage          = "${var.db_size}"
  storage_type               = "${var.db_storage_type}"
  storage_encrypted          = "${var.db_storage_encrypted}"
  kms_key_id                 = "${aws_kms_key.rds_encryption_key.arn}"
  engine                     = "${var.db_engine}"
  engine_version             = "${var.db_version}"
  port                       = "${var.db_port}"
  instance_class             = "${var.db_instance_class}"
  name                       = "${var.db_name}"
  identifier                 = "${lower(var.db_identifier)}"
  username                   = "${var.db_username}"
  password                   = "${var.db_password}"
  db_subnet_group_name       = "${aws_db_subnet_group.db_subnet_group.id}"
  parameter_group_name       = "${aws_db_parameter_group.db_parameter.id}"
  publicly_accessible        = "${var.db_publicly_accessible}"
  vpc_security_group_ids     = ["${aws_security_group.database_sg.id}"]
  multi_az                   = "${var.db_multi_availability_zone}"
  maintenance_window         = "${var.db_maintenance_window}"
  auto_minor_version_upgrade = "${var.db_auto_minor_version_upgrade}"
  backup_retention_period    = "${var.db_backup_retention_period}"
  backup_window              = "${var.db_backup_window}"
  skip_final_snapshot        = "${var.db_skip_final_snapshot}"
  copy_tags_to_snapshot      = "${var.db_copy_tags_to_snapshot}"
  iops                       = "${var.db_iops}"

  lifecycle {
    prevent_destroy = false
  }

  tags {
    Name        = "${lower(var.db_identifier)}"
    Project     = "${var.project_key}"
    Creator     = "${var.aws_email}"
    Environment = "${var.environment}"
  }
}
