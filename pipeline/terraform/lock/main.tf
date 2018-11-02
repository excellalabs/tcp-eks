provider "aws" {
  region                  = "${var.aws_region}"
  shared_credentials_file = "${var.aws_credentials_filepath}"
  profile                 = "${var.aws_profile}"
}

terraform {
  backend "s3" {
    encrypt = true

    # ...the other parameters are set in the Jenkinsfile via the -backend-config parameter
  }
}

resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
  name           = "${var.app_name}-terraform-state-lock"
  hash_key       = "LockID"
  read_capacity  = 1
  write_capacity = 1

  attribute {
    name = "LockID"
    type = "S"
  }

  tags {
    Name = "DynamoDB Terraform State Lock Table"
  }
}

resource "aws_ssm_parameter" "terraform-state-lock-table" {
  name      = "${var.app_name}-terraform-state-lock-table"
  type      = "String"
  value     = "${aws_dynamodb_table.dynamodb-terraform-state-lock.name}"
  overwrite = true
}
