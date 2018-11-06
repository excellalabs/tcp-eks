resource "aws_sns_topic" "eks_events" {
  name = "eks_events_${var.environment}_${var.cluster_name}"
}

data "template_file" "eks_task_stopped" {
  template = <<EOF
{
  "source": ["aws.eks"],
  "detail-type": ["EKS Task State Change"],
  "detail": {
    "clusterArn": ["arn:aws:eks:$${aws_region}:$${account_id}:cluster/$${cluster_name}"],
    "lastStatus": ["STOPPED"],
    "stoppedReason": ["Essential container in task exited"]
  }
}
EOF

  vars {
    account_id   = "${data.aws_caller_identity.current.account_id}"
    cluster_name = "${var.cluster_name}"
    aws_region   = "${data.aws_region.current.name}"
  }
}

resource "aws_cloudwatch_event_rule" "eks_task_stopped" {
  name          = "${var.environment}_${var.cluster_name}_task_stopped"
  description   = "${var.environment}_${var.cluster_name} Essential container in task exited"
  event_pattern = "${data.template_file.eks_task_stopped.rendered}"
}

resource "aws_cloudwatch_event_target" "event_fired" {
  rule  = "${aws_cloudwatch_event_rule.eks_task_stopped.name}"
  arn   = "${aws_sns_topic.eks_events.arn}"
  input = "{ \"message\": \"Essential container in task exited\", \"account_id\": \"${data.aws_caller_identity.current.account_id}\", \"cluster\": \"${var.cluster_name}\"}"
}