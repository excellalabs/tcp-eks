data "aws_caller_identity" "current" {}

variable "project_key" {
  description = "The project name you wish to use"
}

variable "environment" {
  description = "The environment you wish to use"
}

variable "aws_region" {
  description = "The region you wish to use"
}

variable "aws_email" {
  description = "the user email address"
}

variable "aws_secret_key" {
  description = "Amazon Web Service Secret Key"
}

variable "aws_access_key" {
  description = "Amazon Web Service Access Key"
}

variable "slack_webhook_path" {
  description = "Slack Webhook path for the alert. Obtained via, https://api.slack.com/incoming-webhooks"
}

variable "slack_channel" {
  description = "The slack channel to send alerts to"
}
