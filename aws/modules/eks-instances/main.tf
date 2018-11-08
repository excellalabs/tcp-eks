resource "aws_security_group" "instance" {
  name        = "${var.environment}-${var.cluster_name}-${var.instance_group}"
  description = "Used in ${var.environment}"
  vpc_id      = "${var.vpc_id}"

  tags {
    Name          = "${var.environment}-${var.cluster_name}-${var.instance_group}"
    Cluster       = "${var.cluster_name}"
    Creator       = "${var.aws_email}"
    Environment   = "${var.environment}"
    InstanceGroup = "${var.instance_group}"
  }
}

resource "aws_security_group_rule" "outbound_internet_access" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.instance.id}"
}

resource "aws_security_group_rule" "bastion_ssh_access" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "-1"
  cidr_blocks       = "${var.bastion_cidrs}"
  security_group_id = "${aws_security_group.instance.id}"
}

resource "aws_launch_configuration" "launch" {
  name_prefix          = "${var.environment}-${var.cluster_name}-${var.instance_group}-"
  image_id             = "${var.aws_ami}"
  instance_type        = "${var.instance_type}"
  security_groups      = ["${aws_security_group.instance.id}"]
  iam_instance_profile = "${var.iam_instance_profile_id}"
  key_name             = "${var.key_name}"
  user_data_base64     = "${base64encode(element(data.template_file.user_data.*.rendered, count.index))}"
  ebs_optimized        = "${var.ebs_optimized}"
  enable_monitoring    = "${var.enable_monitoring}"
  spot_price           = "${var.spot_price}"
  placement_tenancy    = "${var.placement_tenancy}"
  associate_public_ip_address = "${var.public_ip_associated}"

  # aws_launch_configuration cannot be modified.
  # Therefore we use create_before_destroy so that a new modified aws_launch_configuration can be created
  # before the old one gets destroyed. That's why we use name_prefix instead of name.
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
resource "aws_autoscaling_group" "asg" {
  name                  = "${var.environment}-${var.cluster_name}-${var.instance_group}"
  max_size              = "${var.max_size}"
  min_size              = "${var.min_size}"
  desired_capacity      = "${var.desired_capacity}"
  launch_configuration  = "${aws_launch_configuration.launch.id}"
  vpc_zone_identifier   = ["${var.private_subnet_ids}"]
  load_balancers        = ["${var.load_balancers}"]
  target_group_arns     = ["${var.target_group_arns}"]
  protect_from_scale_in = "${var.protect_from_scale_in}"
  suspended_processes   = ["${var.suspended_processes}"]
  force_delete          = true

  tag {
    key                 = "Name"
    value               = "${var.environment}-eks-${var.cluster_name}-${var.instance_group}"
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
    key                 = "InstanceGroup"
    value               = "${var.instance_group}"
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

data "template_file" "user_data" {
  template = "${file("${path.module}/templates/user_data.sh")}"

  vars {
    eks_config        = "${var.eks_config}"
    eks_logging       = "${var.eks_logging}"
    cluster_name      = "${var.cluster_name}-${var.environment}"
    env_name          = "${var.environment}"
    custom_userdata   = "${var.custom_userdata}"
    cloudwatch_prefix = "${var.cloudwatch_prefix}"
  }
}
