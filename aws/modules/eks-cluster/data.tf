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

data "aws_iam_policy_document" "cluster_assume_role_policy" {
  statement {
    sid = "EKSClusterAssumeRole"

    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
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

data "template_file" "userdata" {
  template = "${file("${path.module}/templates/userdata.sh.tpl")}"
  count    = "${var.worker_group_count}"

  vars {
    cluster_name        = "${aws_eks_cluster.cluster.name}"
    endpoint            = "${aws_eks_cluster.cluster.endpoint}"
    cluster_auth_base64 = "${aws_eks_cluster.cluster.certificate_authority.0.data}"
    pre_userdata        = "${var.pre_userdata}"
    additional_userdata = "${var.additional_userdata}"
    kubelet_extra_args  = "${var.kubelet_extra_args}"
  }
}

data "template_file" "worker_role_arns" {
  count    = "${var.worker_group_count}"
  template = "${file("${path.module}/templates/worker-role.tpl")}"

  vars {
    worker_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${element(aws_iam_instance_profile.cluster_node.*.role, count.index)}"
  }
}

data "template_file" "config_map_aws_auth" {
  template = "${file("${path.module}/templates/config-map-aws-auth.yaml.tpl")}"

  vars {
    worker_role_arn = "${join("", distinct(data.template_file.worker_role_arns.*.rendered))}"
  }
}

data "template_file" "kubeconfig" {
  template = "${file("${path.module}/templates/kubeconfig.tpl")}"

  vars {
    cluster_name             = "${aws_eks_cluster.cluster.name}"
    endpoint                 = "${aws_eks_cluster.cluster.endpoint}"
    region                   = "${data.aws_region.current.name}"
    cluster_auth_base64      = "${aws_eks_cluster.cluster.certificate_authority.0.data}"
    aws_auth_command         = "${var.kubeconfig_aws_auth_command}"
    aws_auth_command_args    = "${length(var.kubeconfig_aws_auth_command_args) > 0 ? "        - ${join("\n        - ", var.kubeconfig_aws_auth_command_args)}" : "        - ${join("\n        - ", formatlist("\"%s\"", list("token", "-i", aws_eks_cluster.cluster.name)))}"}"
    aws_auth_additional_args = "${length(var.kubeconfig_aws_auth_additional_args) > 0 ? "        - ${join("\n        - ", var.kubeconfig_aws_auth_additional_args)}" : ""}"
    aws_auth_env_variables   = "${length(var.kubeconfig_aws_auth_env_variables) > 0 ? "      env:\n${join("\n", data.template_file.aws_auth_env_variables.*.rendered)}" : ""}"
  }
}

data "template_file" "aws_auth_env_variables" {
  template = <<EOF
        - name: $${key}
          value: $${value}
EOF

  count = "${length(var.kubeconfig_aws_auth_env_variables)}"

  vars {
    value = "${element(values(var.kubeconfig_aws_auth_env_variables), count.index)}"
    key   = "${element(keys(var.kubeconfig_aws_auth_env_variables), count.index)}"
  }
}

locals {
  cluster_node_userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.cluster.endpoint}' --b64-cluster-ca '${aws_eks_cluster.cluster.certificate_authority.0.data}' '${var.cluster_name}'
USERDATA
}