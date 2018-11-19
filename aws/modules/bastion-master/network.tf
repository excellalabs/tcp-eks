module "bastion_subnet" {
  source = "../subnet"

  name               = "${var.project_key}-bastion-public-subnet"
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

resource "aws_security_group" "bastion_sg" {
  name        = "${var.project_key}-bastion-security-group"
  description = "Allow SSH/RDS access"
  vpc_id      = "${var.vpc_id}"

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol    = -1
    from_port   = 0 
    to_port     = 0 
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name        = "${var.project_key}-bastion-security-group"
    Project     = "${var.project_key}"
    Creator     = "${var.aws_email}"
    Environment = "${var.environment}"
  }
}
