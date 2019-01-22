# Cluster IAM Policy
resource "aws_iam_policy" "cluster_policy" {
  name   = "${var.cluster_name}-${var.environment}-cluster-policy"
  path   = "/"
  policy = "${data.template_file.cluster_policy.rendered}"
}

resource "aws_iam_policy_attachment" "cluster_policy_attachment" {
  name       = "${var.cluster_name}-${var.environment}-cluster-policy-attachment"
  roles      = ["${aws_iam_role.cluster_role.name}"]
  policy_arn = "${aws_iam_policy.cluster_policy.arn}"
}

# IAM role used by cluster for EC2 policy
resource "aws_iam_role_policy_attachment" "ec2_cluster_role" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  role       = "${aws_iam_role.cluster_role.id}"
}

# IAM role used by cluster for CloudWatch policy
resource "aws_iam_role_policy_attachment" "cloudwatch_cluster_role" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  role       = "${aws_iam_role.cluster_role.id}"
}

# EKS Cluster IAM Roles
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.cluster_role.name}"
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.cluster_role.name}"
}