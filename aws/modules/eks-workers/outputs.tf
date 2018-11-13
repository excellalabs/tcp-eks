output "workers_asg_arns" {
  description = "IDs of the autoscaling groups containing workers."
  value       = "${aws_autoscaling_group.workers.*.arn}"
}

output "workers_asg_names" {
  description = "Names of the autoscaling groups containing workers."
  value       = "${aws_autoscaling_group.workers.*.id}"
}

output "worker_security_group_id" {
  description = "Security group ID attached to the cluster workers."
  value       = "${aws_security_group.workers.*.id}"
}

output "worker_iam_role_name" {
  description = "default IAM role name for cluster worker groups"
  value       = "${aws_iam_role.workers.name}"
}

output "worker_iam_role_arn" {
  description = "default IAM role ARN for cluster worker groups"
  value       = "${aws_iam_role.workers.arn}"
}
