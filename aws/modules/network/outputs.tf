output "private_subnet_ids" {
  value = "${module.private_subnet.ids}"
}

output "public_subnet_ids" {
  value = "${module.public_subnet.ids}"
}

output "depends_id" {
  value = "${null_resource.dummy_dependency.id}"
}

resource "aws_ssm_parameter" "ecs_private_subnet_ids" {
  name      = "${var.environment}_ecs_private_subnet_ids"
  type      = "String"
  value     = "${join(",", module.private_subnet.ids)}"
  overwrite = true
}

output "nat_ids" {
  value = ["${aws_nat_gateway.nat.*.id}"]
}
