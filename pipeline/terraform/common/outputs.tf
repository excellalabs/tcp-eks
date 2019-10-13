output "rails_base_ecr_repository_url" {
  value = "${aws_ecr_repository.rails_base.repository_url}"
}

output "rails_pipeline_ecr_repository_url" {
  value = "${aws_ecr_repository.rails_pipeline.repository_url}"
}

resource "aws_ssm_parameter" "rails_base_ecr_repo" {
  name      = "rails_base_ecr_url"
  type      = "String"
  value     = "${aws_ecr_repository.rails_base.repository_url}"
  overwrite = true
}

resource "aws_ssm_parameter" "rails_pipeline_ecr_repo" {
  name      = "rails_pipeline_ecr_url"
  type      = "String"
  value     = "${aws_ecr_repository.rails_pipeline.repository_url}"
  overwrite = true
}

output "node_base_ecr_repository_url" {
  value = "${aws_ecr_repository.node_base.repository_url}"
}

output "node_pipeline_ecr_repository_url" {
  value = "${aws_ecr_repository.node_pipeline.repository_url}"
}

resource "aws_ssm_parameter" "node_base_ecr_repo" {
  name      = "node_base_ecr_url"
  type      = "String"
  value     = "${aws_ecr_repository.node_base.repository_url}"
  overwrite = true
}

resource "aws_ssm_parameter" "node_pipeline_ecr_repo" {
  name      = "node_pipeline_ecr_url"
  type      = "String"
  value     = "${aws_ecr_repository.node_pipeline.repository_url}"
  overwrite = true
}
