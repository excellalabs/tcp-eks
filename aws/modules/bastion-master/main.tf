resource "aws_key_pair" "bastion" {
  key_name   = "${var.bastion_key_name}"
  public_key = "${file(var.bastion_public_key_path)}"
}

resource "aws_instance" "bastion" {
  ami                         = "${data.aws_ami.ubuntu.id}"
  key_name                    = "${aws_key_pair.bastion.key_name}"
  instance_type               = "${var.bastion_instance_type}"
  subnet_id                   = "${module.bastion_subnet.ids[0]}"
  vpc_security_group_ids      = ["${aws_security_group.bastion_sg.id}"]
  associate_public_ip_address = "${var.bastion_associate_public_ip_address}"
  tags {
    Name        = "bastion_master"
    Project     = "${var.project_key}"
    Creator     = "${var.aws_email}"
    Environment = "${var.environment}"
  }
  connection {
    user        = "ubuntu"
    private_key = "${file(var.bastion_private_key_path)}"
  }
}
