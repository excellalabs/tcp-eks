resource "aws_eks_cluster" "cluster" {
  name     = "${var.cluster_name}"
  role_arn = "${aws_iam_role.cluster_role.arn}"
  version  = "${var.cluster_version}"

  vpc_config {
    security_group_ids = ["${aws_security_group.cluster.id}"]
    subnet_ids         = ["${var.public_subnet}"]
  }
  timeouts {
    create = "${var.cluster_create_timeout}"
    delete = "${var.cluster_delete_timeout}"
  }
  depends_on = [
    "aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.cluster_AmazonEKSServicePolicy",
  ]
}

resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name        = "${var.cluster_name}-sg"
    Project     = "${var.name}"
    Creator     = "${var.aws_email}"
    Environment = "${var.environment}"
  }
}
/*
module "alb" {
  source = "../alb"

  cluster_name      = "${var.cluster_name}"
  environment       = "${var.environment}"
  alb_name          = "${var.name}"
  vpc_id            = "${var.vpc_id}"
  public_subnet_ids = ["${var.public_subnet}"]
  aws_email          = "${var.aws_email}"
}

resource "aws_security_group_rule" "alb_to_cluster" {
  type                     = "ingress"
  from_port                = 32768
  to_port                  = 61000
  protocol                 = "TCP"
  source_security_group_id = "${module.alb.alb_security_group_id}"
  security_group_id        = "${module.eks-workers.worker_security_group_id}"
}

module "eks-workers" {
  source = "../eks-workers"

  environment             = "${var.environment}"
  cluster_name            = "${aws_eks_cluster.cluster.name}"
  worker_name             = "${var.cluster_name}"
  bastion_cidrs           = "${var.cluster_cidrs}"
  worker_group            = "${var.worker_group}"
  private_subnet_ids      = ["${var.private_subnet}"]
  aws_ami                 = "${data.aws_ami.eks_worker.id}"
  aws_email               = "${var.aws_email}"
  instance_type           = "${var.instance_type}"
  max_size                = "${var.max_size}"
  min_size                = "${var.min_size}"
  desired_capacity        = "${var.desired_capacity}"
  vpc_id                  = "${var.vpc_id}"
  iam_instance_profile_id = "${aws_iam_instance_profile.cluster_node.id}"
  key_name                = "${var.key_name}"
  load_balancers          = "${var.load_balancers}"
  depends_id              = "${var.depends_id}"
  custom_userdata         = "${var.custom_userdata}"
  cloudwatch_prefix       = "${var.cloudwatch_prefix}"
  cluster_endpoint        = "${aws_eks_cluster.cluster.endpoint}"
  cluster_security_group_id = "${aws_security_group.cluster.*.id}"
  cluster_certificate_authority_data = "${aws_eks_cluster.cluster.certificate_authority.0.data}"
}
*/
# provides a log group for any applications deployed into this cluster to log to
resource "aws_cloudwatch_log_group" "cluster" {
  name              = "${var.cloudwatch_prefix}"
  retention_in_days = 7
}

resource "aws_kms_key" "cluster" {
  description = "master encryption key for dev, staging, and prod cluster"
}

resource "aws_kms_alias" "cluster" {
  name          = "alias/${var.cluster_name}/${var.environment}/${var.name}-cluster"
  target_key_id = "${aws_kms_key.cluster.key_id}"
}

resource "aws_s3_bucket" "cluster" {
  bucket = "${var.cluster_name}"
  acl    = "private"

  force_destroy = true

  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.cluster.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }
  tags {
    Name        = "${var.cluster_name}"
    Project     = "${var.name}"
    Creator     = "${var.aws_email}"
    Environment = "${var.environment}"
  }
}