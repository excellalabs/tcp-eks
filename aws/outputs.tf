output "alb_target_group" {
  value = "${module.ecs-cluster.default_alb_target_group}"
}

output "jenkins_master_public_dns" {
  value = "${module.jenkins-master.jenkins_master_public_dns}"
}

output "jenkins_public_subnet_cidrs" {
  value = "${module.jenkins-master.jenkins_public_subnet_cidrs}"
}

# output "ecs_deployer_access_key" {
#   value = "${module.users.ecs_deployer_access_key}"
# }

# output "ecs_deployer_secret_key" {
#   value = "${module.users.ecs_deployer_secret_key}"
# }

resource "aws_ssm_parameter" "project_key" {
  name      = "project_key"
  type      = "String"
  value     = "${var.project_key}"
  overwrite = true
}

resource "aws_ssm_parameter" "db_username" {
  name      = "db_username"
  type      = "SecureString"
  value     = "${var.db_username}"
  overwrite = true
}

resource "aws_ssm_parameter" "db_password" {
  name      = "db_password"
  type      = "SecureString"
  value     = "${var.db_password}"
  overwrite = true
}

resource "aws_ssm_parameter" "terraform-state-bucket" {
  name      = "terraform-state-bucket"
  type      = "String"
  value     = "${aws_s3_bucket.terraform-state-storage-s3.bucket}"
  overwrite = true
}

resource "aws_ssm_parameter" "terraform-state-region" {
  name      = "terraform-state-region"
  type      = "String"
  value     = "${var.aws_region}"
  overwrite = true
}
