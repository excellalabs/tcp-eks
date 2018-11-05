# Database Cloudwatch Alarms and Alerts

resource "aws_cloudwatch_metric_alarm" "database_cpu_alert" {
  alarm_name          = "${aws_db_instance.sql_database.identifier}-cpu-alert"
  evaluation_periods  = "1"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "${var.alarm_cpu_threshold}"
  alarm_description   = "Alert generated if the DB is using more than ${var.alarm_cpu_threshold}% CPU"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.environment}-slack-alert"]
  dimensions {
    DBInstanceIdentifier = "${aws_db_instance.sql_database.identifier}"
  }
}

resource "aws_cloudwatch_metric_alarm" "database_storage_alert" {
  alarm_name          = "${aws_db_instance.sql_database.identifier}-storage-alert"
  evaluation_periods  = "1"
  comparison_operator = "LessThanOrEqualToThreshold"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "${var.db_free_storage_alert_level * 1024 * 1024 * 1024}"
  alarm_description   = "Alert generated if the DB has less than a ${var.db_free_storage_alert_level}GB of spage left"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.environment}-slack-alert"]
  dimensions {
    DBInstanceIdentifier = "${aws_db_instance.sql_database.identifier}"
  }
}

resource "aws_cloudwatch_metric_alarm" "database_free_memory_alert" {
  alarm_name          = "${aws_db_instance.sql_database.identifier}-free-memory-alert"
  evaluation_periods  = "1"
  comparison_operator = "LessThanOrEqualToThreshold"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = "${var.db_free_memory_alert_level * 1024 * 1024}"
  alarm_description   = "Alert generated if the DB has less than a ${var.db_free_memory_alert_level}MB of memory left"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.environment}-slack-alert"]
  dimensions {
    DBInstanceIdentifier = "${aws_db_instance.sql_database.identifier}"
  }
}

resource "aws_cloudwatch_metric_alarm" "database_disk_queue" {
  alarm_name          = "${aws_db_instance.sql_database.identifier}-disk-queue-depth-alert"
  evaluation_periods  = "1"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "DiskQueueDepth"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = "${var.alarm_disk_queue_threshold}"
  alarm_description   = "Alert generated for Database server disk queue depth of ${var.alarm_disk_queue_threshold}"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.environment}-slack-alert"]
  dimensions {
    DBInstanceIdentifier = "${aws_db_instance.sql_database.id}"
  }
}

resource "aws_cloudwatch_metric_alarm" "database_cpu_credit" {
  alarm_name          = "${aws_db_instance.sql_database.identifier}-cpu-credit-balance-alert"
  evaluation_periods  = "1"
  comparison_operator = "LessThanThreshold"
  metric_name         = "CPUCreditBalance"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = "${var.alarm_cpu_credit_balance_threshold}"
  alarm_description   = "Alert generated for Database CPU credit balance of ${var.alarm_cpu_credit_balance_threshold}"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.environment}-slack-alert"]
  dimensions {
    DBInstanceIdentifier = "${aws_db_instance.sql_database.id}"
  }
}
