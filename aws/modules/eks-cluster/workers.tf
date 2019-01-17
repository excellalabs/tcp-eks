resource "aws_autoscaling_group" "cluster" {
  name                  = "${aws_eks_cluster.cluster.name}-asg"
  desired_capacity      = "${var.desired_capacity}"
  max_size              = "${var.max_size}"
  min_size              = "${var.min_size}"
  launch_configuration  = "${aws_launch_configuration.cluster.id}"
  vpc_zone_identifier   = ["${module.network.private_subnet_ids}"]
  protect_from_scale_in = "${var.protect_from_scale_in}"
  suspended_processes   = ["${var.suspended_processes}"]
  count                 = "${var.worker_group_count}"
  force_delete          = true

  lifecycle {
    ignore_changes = ["desired_capacity"]
  }

  tag {
    key                 = "Name"
    value               = "${aws_eks_cluster.cluster.name}-${var.worker_group}"
    propagate_at_launch = "true"
  }
  tag {
    key                 = "kubernetes.io/cluster/${aws_eks_cluster.cluster.name}"
    value               = "owned"
    propagate_at_launch = true
  }
  tag {
    key                 = "Environment"
    value               = "${var.environment}"
    propagate_at_launch = "true"
  }
  tag {
    key                 = "Cluster"
    value               = "${var.cluster_name}"
    propagate_at_launch = "true"
  }
  tag {
    key                 = "WorkerGroup"
    value               = "${var.worker_group}"
    propagate_at_launch = "true"
  }
  # EC2 instances require internet connectivity to boot
  # Thus EC2 instances must not start before NAT is available
  # For reason why see description in the network module
  tag {
    key                 = "DependsId"
    value               = "${module.network.depends_id}"
    propagate_at_launch = "false"
  }
}

resource "aws_launch_configuration" "cluster" {
  associate_public_ip_address = true

  iam_instance_profile = "${aws_iam_instance_profile.cluster_node.name}"
  image_id             = "${data.aws_ami.eks_worker.id}"
  instance_type        = "${var.instance_type}"
  name_prefix          = "${var.cluster_name}-cluster"
  security_groups      = ["${aws_security_group.cluster_node.id}"]
  user_data_base64     = "${base64encode(local.cluster_node_userdata)}"

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_size           = "${var.root_volume_size}"
    volume_type           = "${var.root_volume_type}"
    iops                  = "${var.root_iops}"
    delete_on_termination = true
  }
}

resource "aws_security_group" "cluster_node" {
  name        = "${aws_eks_cluster.cluster.name}-node-security-group"
  description = "Security group for all nodes in the cluster."
  vpc_id      = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = "${
    map(
     "Name", "${aws_eks_cluster.cluster.name}-node-sg",
     "Project", "${var.name}",
     "Creator", "${var.aws_email}",
     "Environment", "${var.environment}",
     "kubernetes.io/cluster/${var.cluster_name}", "owned",
    )
  }"
}

resource "aws_security_group_rule" "cluster_node_ingress_self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.cluster_node.id}"
  source_security_group_id = "${aws_security_group.cluster_node.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster_node_ingress" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.cluster_node.id}"
  source_security_group_id = "${aws_security_group.cluster.id}"
  to_port                  = 65535
  type                     = "ingress"
}

# Worker Node Access to EKS Master Cluster
resource "aws_security_group_rule" "cluster_ingress_node_https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.cluster.id}"
  source_security_group_id = "${aws_security_group.cluster_node.id}"
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_iam_role" "workers" {
  name               = "${aws_eks_cluster.cluster.name}"
  assume_role_policy = "${data.aws_iam_policy_document.workers_assume_role_policy.json}"
}

resource "aws_iam_instance_profile" "workers" {
  name_prefix = "${aws_eks_cluster.cluster.name}"
  role        = "${lookup(var.worker_groups[count.index], "iam_role_id",
                "${element(concat(aws_iam_role.workers.*.id, list("")), 0)}")}"
  count       = "${var.worker_group_count}"
}

resource "aws_iam_role_policy_attachment" "workers_autoscaling" {
  policy_arn = "${aws_iam_policy.worker_autoscaling.arn}"
  role       = "${aws_iam_role.workers.name}"
}

resource "aws_iam_policy" "worker_autoscaling" {
  name_prefix = "${aws_eks_cluster.cluster.name}-worker-autoscaling"
  description = "Cluster Worker Node AutoScaling Policy"
  policy      = "${data.aws_iam_policy_document.worker_autoscaling.json}"
}

data "aws_iam_policy_document" "worker_autoscaling" {
  statement {
    sid    = "eksWorkerAutoscalingAll"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:GetAsgForInstance",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "eksWorkerAutoscalingOwn"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${aws_eks_cluster.cluster.name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }
  }
}