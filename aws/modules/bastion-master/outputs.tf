output "bastion_public_dns" {
  value = "${aws_instance.bastion.public_dns}"
}

output "bastion_subnet_cidrs" {
  value = "${var.bastion_cidrs}"
}

output "ami_id" {
  value = "${data.aws_ami.ubuntu.id}"
}
