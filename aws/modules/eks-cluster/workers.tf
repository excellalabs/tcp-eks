resource "aws_autoscaling_group" "workers" {
  name_prefix           = "${aws_eks_cluster.cluster.name}-${lookup(var.worker_groups[count.index], "name", count.index)}"
  desired_capacity      = "${var.desired_capacity}"
  max_size              = "${var.max_size}"
  min_size              = "${var.min_size}"
  target_group_arns     = ["${var.target_group_arns}"]
  launch_configuration  = "${element(aws_launch_configuration.workers.*.id, count.index)}"
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
    value               = "${var.environment}-${var.cluster_name}-${var.worker_group}"
    propagate_at_launch = "true"
  }
  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
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

resource "aws_launch_configuration" "workers" {
  name_prefix                 = "${aws_eks_cluster.cluster.name}-${lookup(var.worker_groups[count.index], "name", count.index)}"
  associate_public_ip_address = "${var.public_ip_associated}"
  security_groups             = ["${coalesce(join("", aws_security_group.workers.*.id), var.worker_security_group_id)}"]
  iam_instance_profile        = "${element(aws_iam_instance_profile.workers.*.id, count.index)}"
  image_id                    = "${data.aws_ami.eks_worker.id}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.key_name}"
  user_data_base64            = "${base64encode(element(data.template_file.userdata.*.rendered, count.index))}"
  ebs_optimized               = "${var.ebs_optimized}"
  enable_monitoring           = "${var.enable_monitoring}"
  spot_price                  = "${var.spot_price}"
  placement_tenancy           = "${var.placement_tenancy}"
  count                       = "${var.worker_group_count}"

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

resource "aws_security_group" "workers" {
  name_prefix = "${aws_eks_cluster.cluster.name}"
  description = "Security group for all nodes in the cluster."
  vpc_id      = "${var.vpc_id}"
  count       = "${var.worker_security_group_id == "" ? 1 : 0}"
  tags {
    Name        = "${var.environment}-${var.cluster_name}-eks-worker-sg"
    Project     = "${var.cluster_name}"
    Creator     = "${var.aws_email}"
    Environment = "${var.environment}"
  }
}

resource "aws_security_group_rule" "workers_egress_internet" {
  description       = "Allow nodes all egress to the Internet"
  protocol          = "-1"
  security_group_id = "${aws_security_group.workers.id}"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  type              = "egress"
  count             = "${var.worker_security_group_id == "" ? 1 : 0}"
}

resource "aws_security_group_rule" "workers_ingress_self" {
  description              = "Allow node to communicate with each other"
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.workers.id}"
  source_security_group_id = "${aws_security_group.workers.id}"
  from_port                = 0
  to_port                  = 65535
  type                     = "ingress"
  count                    = "${var.worker_security_group_id == "" ? 1 : 0}"
}

resource "aws_security_group_rule" "workers_ingress_cluster" {
  description              = "Allow workers Kubelets and pods to receive communication from the cluster control plane"
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.workers.id}"
  source_security_group_id = "${coalesce(join("", aws_security_group.cluster.*.id), var.cluster_security_group_id)}"
  from_port                = "${var.worker_sg_ingress_from_port}"
  to_port                  = 65535
  type                     = "ingress"
  count                    = "${var.worker_security_group_id == "" ? 1 : 0}"
}

resource "aws_security_group_rule" "workers_ingress_cluster_https" {
  description              = "Allow pods running extension API servers on port 443 to receive communication from cluster control plane."
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.workers.id}"
  source_security_group_id = "${coalesce(join("", aws_security_group.cluster.*.id), var.cluster_security_group_id)}"
  from_port                = 443
  to_port                  = 443
  type                     = "ingress"
  count                    = "${var.worker_security_group_id == "" ? 1 : 0}"
}

resource "aws_iam_role" "workers" {
  name_prefix        = "${aws_eks_cluster.cluster.name}"
  assume_role_policy = "${data.aws_iam_policy_document.workers_assume_role_policy.json}"
}

resource "aws_iam_instance_profile" "workers" {
  name_prefix = "${aws_eks_cluster.cluster.name}"
  role        = "${lookup(var.worker_groups[count.index], "iam_role_id",
                "${element(concat(aws_iam_role.workers.*.id, list("")), 0)}")}"
  count       = "${var.worker_group_count}"
}

resource "aws_iam_role_policy_attachment" "workers_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.workers.name}"
}

resource "aws_iam_role_policy_attachment" "workers_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.workers.name}"
}

resource "aws_iam_role_policy_attachment" "workers_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.workers.name}"
}

resource "aws_iam_role_policy_attachment" "workers_autoscaling" {
  policy_arn = "${aws_iam_policy.worker_autoscaling.arn}"
  role       = "${aws_iam_role.workers.name}"
}

resource "aws_iam_policy" "worker_autoscaling" {
  name_prefix = "eks-worker-autoscaling-${aws_eks_cluster.cluster.name}"
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
