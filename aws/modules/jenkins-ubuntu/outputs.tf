output "jenkins_master_public_dns" {
  value = "${aws_instance.jenkins_ubuntu.public_dns}"
}

output "jenkins_public_subnet_cidrs" {
  value = "${var.public_subnet_cidrs}"
}

output "ami_id" {
  value = "${data.aws_ami.ubuntu.id}"
}
