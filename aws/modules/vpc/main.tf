resource "aws_vpc" "vpc" {
  cidr_block           = "${var.cidr}"
  enable_dns_hostnames = true
  tags {
    Name    = "${var.name}-vpc"
    Project = "${var.name}"
    Creator     = "${var.aws_email}"
    Environment = "${var.environment}"
  }
}

resource "aws_internet_gateway" "vpc" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags {
    Name    = "${var.name}-igw"
    Project = "${var.name}"
    Creator     = "${var.aws_email}"
    Environment = "${var.environment}"
  }
}

# Security group allowing internal traffic (inside VPC)
resource "aws_security_group" "internal" {
  vpc_id      = "${aws_vpc.vpc.id}"
  name        = "internal"
  description = "Allow internal traffic"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr}"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name        = "${var.name}-internal-security-group"
    Project     = "${var.name}"
    Creator     = "${var.aws_email}"
    Environment = "${var.environment}"
  }
}

resource "aws_security_group" "ssh" {
  vpc_id      = "${aws_vpc.vpc.id}"
  name        = "ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name        = "${var.name}-ssh-security-group"
    Project     = "${var.name}"
    Creator     = "${var.aws_email}"
    Environment = "${var.environment}"
  }
}
