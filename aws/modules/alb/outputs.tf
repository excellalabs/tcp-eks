output "alb_security_group_id" {
  value = "${aws_security_group.alb.id}"
}

output "default_alb_target_group" {
  value = "${aws_alb_target_group.default.arn}"
}

resource "aws_ssm_parameter" "aws_alb_arn" {
  name      = "${var.environment}_alb_arn"
  type      = "String"
  value     = "${aws_alb_listener.http.arn}"
  overwrite = true
}

resource "aws_ssm_parameter" "alb_endpoint" {
  name      = "${var.environment}_alb_endpoint"
  type      = "String"
  value     = "${aws_alb.alb.dns_name}"
  overwrite = true
}
