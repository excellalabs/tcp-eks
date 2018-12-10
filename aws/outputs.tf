resource "aws_ssm_parameter" "project_key" {
  name      = "project_key"
  type      = "String"
  value     = "${var.project_key}"
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