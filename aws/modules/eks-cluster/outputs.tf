output "cluster_id" {
  description = "The identity of the EKS cluster."
  value       = "${aws_eks_cluster.cluster.id}"
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster."
  value       = "${aws_eks_cluster.cluster.arn}"
}

output "cluster_certificate_authority_data" {
  description = "Nested attribute containing certificate-authority-data for your cluster. This is the base64 encoded certificate data required to communicate with your cluster."
  value       = "${aws_eks_cluster.cluster.certificate_authority.0.data}"
}

output "cluster_endpoint" {
  description = "The endpoint for your EKS Kubernetes API."
  value       = "${aws_eks_cluster.cluster.endpoint}"
}

output "cluster_version" {
  description = "The Kubernetes server version for the EKS cluster."
  value       = "${aws_eks_cluster.cluster.version}"
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster."
  value       = "${aws_security_group.cluster.*.id}"
}

output "config_map_aws_auth" {
  description = "A kubernetes configuration to authenticate to this EKS cluster."
  value       = "${data.template_file.config_map_aws_auth.rendered}"
}

output "kubeconfig" {
  description = "kubectl config file contents for this EKS cluster."
  value       = "${data.template_file.kubeconfig.rendered}"
}

output "workers_asg_arns" {
  description = "IDs of the autoscaling groups containing workers."
  value       = "${aws_autoscaling_group.workers.*.arn}"
}

output "workers_asg_names" {
  description = "Names of the autoscaling groups containing workers."
  value       = "${aws_autoscaling_group.workers.*.id}"
}

output "worker_security_group_id" {
  description = "Security group ID attached to the EKS workers."
  value       = "${coalesce(join("", aws_security_group.workers.*.id), var.worker_security_group_id)}"
}

output "worker_iam_role_name" {
  description = "default IAM role name for EKS worker groups"
  value       = "${aws_iam_role.workers.name}"
}

output "worker_iam_role_arn" {
  description = "default IAM role ARN for EKS worker groups"
  value       = "${aws_iam_role.workers.arn}"
}

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
  value     = "${aws_eks_cluster.cluster.id}"
  overwrite = true
}

resource "aws_ssm_parameter" "eks_private_subnet_cidrs" {
  name      = "${var.environment}_eks_private_subnet_cidrs"
  type      = "String"
  value     = "${join(",", var.private_subnet_cidrs)}"
  overwrite = true
}

output "eks_default_iam_role_arn" {
  value = "${aws_iam_role.eks_default_task.arn}"
}

resource "aws_ssm_parameter" "eks_default_task_role" {
  name      = "${var.environment}_eks_task_role_arn"
  type      = "String"
  value     = "${aws_iam_role.eks_default_task.arn}"
  overwrite = true
}

resource "aws_ssm_parameter" "secrets_bucket" {
  name      = "${var.cluster_name}_${var.environment}_secrets_bucket"
  type      = "String"
  value     = "${aws_s3_bucket.secrets.bucket}"
  overwrite = true
}
