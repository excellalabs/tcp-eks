# Why we need EKS instance policies http://docs.aws.amazon.com/AmazonEKS/latest/developerguide/instance_IAM_role.html
# EKS roles explained here http://docs.aws.amazon.com/AmazonEKS/latest/developerguide/eks_managed_policies.html
# Some other EKS policy examples http://docs.aws.amazon.com/AmazonEKS/latest/developerguide/IAMPolicyExamples.html

# Load Balancer Policies
resource "aws_iam_role" "eks_lb_role" {
  name = "${var.environment}_${var.cluster}_eks_lb_role"
  path = "/eks/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["eks.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "eks_lb" {
  role       = "${aws_iam_role.eks_lb_role.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

# Instance policies

resource "aws_iam_role" "eks_instance_role" {
  name = "${var.environment}_${var.cluster}_eks_instance_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ec2.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "eks" {
  name = "${var.environment}_${var.cluster}_eks_instance_profile"
  path = "/"
  role = "${aws_iam_role.eks_instance_role.name}"
}

resource "aws_iam_role_policy_attachment" "eks_ec2_role" {
  role       = "${aws_iam_role.eks_instance_role.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "eks_ec2_cloudwatch_role" {
  role       = "${aws_iam_role.eks_instance_role.id}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_kms_key" "logsecrets" {
  description = "master encryption key for dev, staging, and prod secrets"
}

resource "aws_kms_alias" "logsecrets" {
  name          = "alias/${var.cluster}/${var.environment}/logsecrets"
  target_key_id = "${aws_kms_key.logsecrets.key_id}"
}

data "template_file" "log_policy" {
  template = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams"
            ],
            "Resource": [
                "arn:aws:logs:*:*:*"
            ]
        }
    ]
}
EOF

  vars {
    account_id  = "${data.aws_caller_identity.current.account_id}"
    prefix      = "${var.cluster}/${var.environment}/"
    aws_region  = "${data.aws_region.current.name}"
    kms_key_arn = "${aws_kms_key.logsecrets.arn}"
  }
}

resource "aws_iam_policy" "eks_default_log_task" {
  name = "${var.environment}_${var.cluster}_eks_default_log_task"
  path = "/"

  policy = "${data.template_file.log_policy.rendered}"
}

resource "aws_iam_policy_attachment" "eks_default_log_task" {
  name = "${var.environment}_${var.cluster}_eks_default_log_task"

  roles      = ["${aws_iam_role.eks_instance_role.name}"]
  policy_arn = "${aws_iam_policy.eks_default_log_task.arn}"
}
