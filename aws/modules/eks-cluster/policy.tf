# Cluster IAM Policy
resource "aws_iam_policy" "cluster-policy" {
  name   = "${var.cluster_name}-cluster-policy"
  path   = "/"
  policy = "${data.template_file.cluster-policy.rendered}"
}

resource "aws_iam_policy_attachment" "cluster-policy-attachment" {
  name       = "${var.cluster_name}-cluster-policy-attachment"
  roles      = ["${aws_iam_role.cluster-role.name}"]
  policy_arn = "${aws_iam_policy.cluster-policy.arn}"
}

# IAM role used by cluster for EC2 policy
resource "aws_iam_role_policy_attachment" "ec2-cluster-role" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  role       = "${aws_iam_role.cluster-role.id}"
}

# IAM role used by cluster for CloudWatch policy
resource "aws_iam_role_policy_attachment" "cloudwatch-cluster-role" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  role       = "${aws_iam_role.cluster-role.id}"
}

# EKS Cluster IAM Roles
resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.cluster-role.name}"
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.cluster-role.name}"
}