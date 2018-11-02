output "default_alb_target_group" {
  value = "${module.alb.default_alb_target_group}"
}

output "public_subnet_ids" {
  value = "${module.network.public_subnet_ids}"
}

output "secrets_kms_key_id" {
  value = "${aws_kms_key.secrets.key_id}"
}

resource "aws_ssm_parameter" "cluster_id" {
  name      = "${var.environment}_cluster_id"
  type      = "String"
  value     = "${aws_ecs_cluster.cluster.id}"
  overwrite = true
}

resource "aws_ssm_parameter" "ecs_private_subnet_cidrs" {
  name      = "${var.environment}_ecs_private_subnet_cidrs"
  type      = "String"
  value     = "${join(",", var.private_subnet_cidrs)}"
  overwrite = true
}

output "ecs_default_iam_role_arn" {
  value = "${aws_iam_role.ecs_default_task.arn}"
}

resource "aws_ssm_parameter" "ecs_default_task_role" {
  name      = "${var.environment}_ecs_task_role_arn"
  type      = "String"
  value     = "${aws_iam_role.ecs_default_task.arn}"
  overwrite = true
}

resource "aws_ssm_parameter" "secrets_bucket" {
  name      = "${var.cluster}_${var.environment}_secrets_bucket"
  type      = "String"
  value     = "${aws_s3_bucket.secrets.bucket}"
  overwrite = true
}
