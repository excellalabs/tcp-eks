resource "aws_ssm_parameter" "project_name" {
  name      = "project_name"
  type      = "String"
  value     = "${var.project_name}"
  overwrite = true
}

resource "aws_ssm_parameter" "terraform_state_bucket" {
  name      = "terraform_state_bucket"
  type      = "String"
  value     = "${aws_s3_bucket.terraform_state_storage_s3.bucket}"
  overwrite = true
}

resource "aws_ssm_parameter" "terraform_state_region" {
  name      = "terraform_state_region"
  type      = "String"
  value     = "${var.aws_region}"
  overwrite = true
}