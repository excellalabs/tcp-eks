resource "aws_iam_role" "ecs_default_task" {
  name = "${var.environment}_${var.cluster}_default_task"
  path = "/ecs/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": ["ecs.amazonaws.com"]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

data "template_file" "policy" {
  template = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ssm:DescribeParameters",
        "ssm:GetParameterHistory",
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:ssm:$${aws_region}:$${account_id}:parameter/$${prefix}*"
    },
    {
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "$${kms_key_arn}",
      "Effect": "Allow"
    },
    {
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "*",
      "Effect": "Allow"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:RegisterTaskDefinition",
        "ecs:CreateService",
        "ecs:UpdateService",
        "ecs:DeleteService",
        "ecs:Describe*",
        "ecs:List*",
        "ecs:RunTask",
        "ecs:StartTask",
        "ecs:StopTask",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:Describe*",
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:Deregister*",
        "elasticloadbalancing:Register*",
        "sts:AssumeRole"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["iam:PassRole"],
      "Resource": "arn:aws:iam::*:role/ecs/*"
    }
  ]
}
EOF

  vars {
    account_id  = "${data.aws_caller_identity.current.account_id}"
    prefix      = "${var.cluster}/${var.environment}/"
    aws_region  = "${data.aws_region.current.name}"
    kms_key_arn = "${aws_kms_key.secrets.arn}"
  }
}

resource "aws_iam_policy" "ecs_default_task" {
  name = "${var.environment}_${var.cluster}_ecs_default_task"
  path = "/"

  policy = "${data.template_file.policy.rendered}"
}

resource "aws_iam_policy_attachment" "ecs_default_task" {
  name       = "${var.environment}_${var.cluster}_ecs_default_task"
  roles      = ["${aws_iam_role.ecs_default_task.name}"]
  policy_arn = "${aws_iam_policy.ecs_default_task.arn}"
}
