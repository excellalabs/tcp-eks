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

resource "aws_ecr_repository" "rails_base" {
  name = "rails_base"
}

resource "aws_ecr_lifecycle_policy" "rails_base-retention" {
  repository = "${aws_ecr_repository.rails_base.name}"

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 30 images",
            "selection": {
                "tagStatus": "tagged",
                "tagPrefixList": ["v"],
                "countType": "imageCountMoreThan",
                "countNumber": 30
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

resource "aws_ecr_repository" "rails_pipeline" {
  name = "rails_pipeline"
}

resource "aws_ecr_lifecycle_policy" "rails_pipeline-retention" {
  repository = "${aws_ecr_repository.rails_pipeline.name}"

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 30 images",
            "selection": {
                "tagStatus": "tagged",
                "tagPrefixList": ["v"],
                "countType": "imageCountMoreThan",
                "countNumber": 30
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

resource "aws_ecr_repository" "node_base" {
  name = "node_base"
}

resource "aws_ecr_lifecycle_policy" "node_base-retention" {
  repository = "${aws_ecr_repository.node_base.name}"

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 30 images",
            "selection": {
                "tagStatus": "tagged",
                "tagPrefixList": ["v"],
                "countType": "imageCountMoreThan",
                "countNumber": 30
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

resource "aws_ecr_repository" "node_pipeline" {
  name = "node_pipeline"
}

resource "aws_ecr_lifecycle_policy" "node_pipeline-retention" {
  repository = "${aws_ecr_repository.node_pipeline.name}"

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 30 images",
            "selection": {
                "tagStatus": "tagged",
                "tagPrefixList": ["v"],
                "countType": "imageCountMoreThan",
                "countNumber": 30
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}