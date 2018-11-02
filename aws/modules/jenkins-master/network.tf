module "public_subnet" {
  source = "../subnet"

  name               = "jenkins_public_subnet"
  environment        = "jenkins"
  aws_email          = "${var.aws_email}"
  vpc_id             = "${var.vpc_id}"
  cidrs              = "${var.public_subnet_cidrs}"
  availability_zones = "${var.availability_zones}"
}

resource "aws_route" "public_igw_route" {
  count                  = "${length(var.public_subnet_cidrs)}"
  route_table_id         = "${element(module.public_subnet.route_table_ids, count.index)}"
  gateway_id             = "${var.vpc_igw}"
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_security_group" "jenkins-sg" {
  name        = "Jenkins group"
  description = "Allow SSH/HTTP"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 8080
    protocol  = "tcp"
    to_port   = 8080

    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    protocol  = "tcp"
    to_port   = 80

    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0

    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name        = "jenkins-sg"
    Project     = "${var.project_key}"
    Creator     = "${var.aws_email}"
    Environment = "${var.environment}"
  }
}
