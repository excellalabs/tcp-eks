resource "aws_iam_role" "cluster" {
  name_prefix        = "${var.cluster_name}"
  assume_role_policy = "${data.aws_iam_policy_document.cluster_assume_role_policy.json}"
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.cluster.name}"
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.cluster.name}"
}

resource "aws_iam_role" "eks_default_task" {
  name = "${var.environment}_${var.cluster_name}_task"
  path = "/eks/"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": ["eks.amazonaws.com"]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

data "template_file" "policy" {
  template = <<POLICY
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
        "eks:RegisterTaskDefinition",
        "eks:CreateService",
        "eks:UpdateService",
        "eks:DeleteService",
        "eks:Describe*",
        "eks:List*",
        "eks:RunTask",
        "eks:StartTask",
        "eks:StopTask",
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
      "Resource": "arn:aws:iam::*:role/eks/*"
    }
  ]
}
POLICY

  vars {
    account_id  = "${data.aws_caller_identity.current.account_id}"
    prefix      = "${var.cluster_name}/${var.environment}/"
    aws_region  = "${data.aws_region.current.name}"
    kms_key_arn = "${aws_kms_key.secrets.arn}"
  }
}

resource "aws_iam_policy" "eks_default_task" {
  name   = "${var.environment}_${var.cluster_name}_eks_task"
  path   = "/"
  policy = "${data.template_file.policy.rendered}"
}

resource "aws_iam_policy_attachment" "eks_default_task" {
  name       = "${var.environment}_${var.cluster_name}_eks_task"
  roles      = ["${aws_iam_role.eks_default_task.name}"]
  policy_arn = "${aws_iam_policy.eks_default_task.arn}"
}
