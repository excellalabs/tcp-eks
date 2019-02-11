module "bastion_subnet" {
  source = "../subnet"

  name               = "${var.name}-bastion-public-subnet"
  environment        = "bastion"
  aws_email          = "${var.aws_email}"
  vpc_id             = "${var.vpc_id}"
  cidrs              = "${var.bastion_cidrs}"
  availability_zones = "${var.availability_zones}"
}

resource "aws_route" "public_igw_route" {
  count                  = "${length(var.bastion_cidrs)}"
  route_table_id         = "${element(module.bastion_subnet.route_table_ids, count.index)}"
  gateway_id             = "${var.vpc_igw}"
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_security_group" "bastion" {
  name        = "${var.name}-bastion-security-group"
  description = "Allow SSH/RDS access"
  vpc_id      = "${var.vpc_id}"

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = "${var.bastion_ssh_cidr}"
  }
  ingress {
    from_port   = "${var.bastion_port}"
    to_port     = "${var.bastion_port}"
    protocol    = "TCP"
    cidr_blocks = "${var.bastion_ssh_cidr}"
  }
  egress {
    protocol    = -1
    from_port   = 0 
    to_port     = 0 
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name        = "${var.name}-bastion-security-group"
    Project     = "${var.name}"
    Owner       = "${var.aws_email}"
    Environment = "${var.environment}"
  }
}