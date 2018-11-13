resource "aws_security_group" "workers" {
  name_prefix = "${var.worker_name}-${var.worker_group}-"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${var.vpc_id}"
  count       = "${var.worker_security_group_id == "" ? 1 : 0}"
  tags {
    Name        = "${var.worker_name}-cluster-worker-sg"
    Cluster     = "${var.cluster_name}"
    Creator     = "${var.aws_email}"
    Environment = "${var.environment}"
    WorkerGroup = "${var.worker_group}"
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
  source_security_group_id = "${var.cluster_security_group_id}"
  from_port                = "${var.worker_sg_ingress_from_port}"
  to_port                  = 65535
  type                     = "ingress"
  count                    = "${var.worker_security_group_id == "" ? 1 : 0}"
}

resource "aws_security_group_rule" "workers_ingress_cluster_https" {
  description              = "Allow pods running extension API servers on port 443 to receive communication from cluster control plane."
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.workers.id}"
  source_security_group_id = "${var.cluster_security_group_id}"
  from_port                = 443
  to_port                  = 443
  type                     = "ingress"
  count                    = "${var.worker_security_group_id == "" ? 1 : 0}"
}

resource "aws_security_group_rule" "bastion_ssh_access" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "-1"
  cidr_blocks       = "${var.bastion_cidrs}"
  security_group_id = "${aws_security_group.workers.id}"
}

resource "aws_launch_configuration" "workers" {
  name_prefix          = "${var.worker_name}-${lookup(var.worker_groups[count.index], "name", count.index)}"
  image_id             = "${data.aws_ami.eks_worker.id}"
  instance_type        = "${var.instance_type}"
  security_groups      = ["${aws_security_group.workers.id}"]
  iam_instance_profile = "${var.iam_instance_profile_id}"
  key_name             = "${var.key_name}"
  user_data_base64     = "${base64encode(element(data.template_file.user_data.*.rendered, count.index))}"
  ebs_optimized        = "${var.ebs_optimized}"
  enable_monitoring    = "${var.enable_monitoring}"
  spot_price           = "${var.spot_price}"
  placement_tenancy    = "${var.placement_tenancy}"
  associate_public_ip_address = "${var.public_ip_associated}"

  # aws_launch_configuration cannot be modified.
  # Therefore we use create_before_destroy so that a new modified
  # aws_launch_configuration can be created before the old one gets destroyed.
  # That's why we use name_prefix instead of name.
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

# Instances are scaled across availability zones
# http://docs.aws.amazon.com/autoscaling/latest/userguide/auto-scaling-benefits.html
resource "aws_autoscaling_group" "workers" {
  name_prefix           = "${var.worker_name}-${lookup(var.worker_groups[count.index], "name", count.index)}"
  max_size              = "${var.max_size}"
  min_size              = "${var.min_size}"
  desired_capacity      = "${var.desired_capacity}"
  launch_configuration  = "${aws_launch_configuration.workers.id}"
  vpc_zone_identifier   = ["${var.private_subnet_ids}"]
  load_balancers        = ["${var.load_balancers}"]
  target_group_arns     = ["${var.target_group_arns}"]
  protect_from_scale_in = "${var.protect_from_scale_in}"
  suspended_processes   = ["${var.suspended_processes}"]
  count                 = "${var.worker_group_count}"
  force_delete          = true

  lifecycle {
    ignore_changes = ["desired_capacity"]
  }

  tag {
    key                 = "Name"
    value               = "${var.worker_name}-${var.worker_group}"
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
    value               = "${var.depends_id}"
    propagate_at_launch = "false"
  }
}

resource "aws_iam_role" "workers" {
  name_prefix        = "${var.worker_name}"
  assume_role_policy = "${data.aws_iam_policy_document.workers_assume_role_policy.json}"
}

resource "aws_iam_instance_profile" "workers" {
  name_prefix = "${var.worker_name}"
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
  name_prefix = "${var.worker_name}-cluster-worker-autoscaling"
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
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${var.worker_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_ami" "eks_worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-v*"]
  }
  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

data "aws_iam_policy_document" "workers_assume_role_policy" {
  statement {
    sid = "EKSWorkerAssumeRole"

    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/templates/user_data.sh.tpl")}"

  vars {
    cluster_config    = "${var.cluster_config}"
    cluster_logging   = "${var.cluster_logging}"
    cluster_name      = "${var.environment}-${var.cluster_name}"
    env_name          = "${var.environment}"
    custom_userdata   = "${var.custom_userdata}"
    cloudwatch_prefix = "${var.cloudwatch_prefix}"
  }
}

data "template_file" "userdata" {
  template = "${file("${path.module}/templates/userdata.sh.tpl")}"
  count    = "${var.worker_group_count}"

  vars {
    cluster_name        = "${var.cluster_name}"
    endpoint            = "${var.cluster_endpoint}"
    cluster_auth_base64 = "${var.cluster_certificate_authority_data}"
    pre_userdata        = "${var.pre_userdata}"
    additional_userdata = "${var.additional_userdata}"
    kubelet_extra_args  = "${var.kubelet_extra_args}"
  }
}

data "template_file" "worker_role_arns" {
  count    = "${var.worker_group_count}"
  template = "${file("${path.module}/templates/worker-role.tpl")}"

  vars {
    worker_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${element(aws_iam_instance_profile.workers.*.role, count.index)}"
  }
}
