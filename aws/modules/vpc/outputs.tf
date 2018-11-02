output "id" {
  value = "${aws_vpc.vpc.id}"
}

output "cidr_block" {
  value = "${aws_vpc.vpc.cidr_block}"
}

output "igw" {
  value = "${aws_internet_gateway.vpc.id}"
}

output "sg-ssh" {
  value = "${aws_security_group.ssh.id}"
}

output "sg-internal" {
  value = "${aws_security_group.internal.id}"
}

resource "aws_ssm_parameter" "vpc_id" {
  name      = "vpc_id"
  type      = "String"
  value     = "${aws_vpc.vpc.id}"
  overwrite = true
}
