# Creates subnet to be used by database instance

resource "aws_subnet" "database_subnet" {
  vpc_id     = "${var.vpc_id}"
  cidr_block = "${element(var.db_subnet_cidrs, count.index)}"
  count      = "${length(var.db_subnet_cidrs)}"

  tags {
    Name        = "${var.project_key}-${var.environment}-${element(var.availability_zones, count.index)}"
    Project     = "${var.project_key}"
    Creator     = "${var.aws_email}"
    Environment = "${var.environment}"
  }

  availability_zone = "${element(var.availability_zones, count.index)}"
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "${var.project_key}-${var.environment}-db-subnet-group"
  description = "Database Subnet Group"

  #subnet_ids  = ["${element(aws_subnet.database_subnet.*.id, count.index)}"]
  subnet_ids = ["${aws_subnet.database_subnet.*.id[0]}",
    "${aws_subnet.database_subnet.*.id[1]}",
  ]

  tags {
    Name        = "${var.project_key}-${var.environment}-db-subnet-group"
    Project     = "${var.project_key}"
    Creator     = "${var.aws_email}"
    Environment = "${var.environment}"
  }
}

# Creates security group and rules to be used by database instance
resource "aws_security_group" "database_sg" {
  name        = "${var.project_key}-${var.environment}-db-security-group"
  description = "Database Security Group"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = "${var.db_port}"
    to_port     = "${var.db_port}"
    protocol    = "TCP"
    cidr_blocks = "${var.db_subnet_cidrs}"
  }

  ingress {
    from_port   = "${var.db_port}"
    to_port     = "${var.db_port}"
    protocol    = "TCP"
    cidr_blocks = ["${var.db_access_cidrs}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "${var.project_key}-db-security-group"
    Project     = "${var.project_key}"
    Creator     = "${var.aws_email}"
    Environment = "${var.environment}"
  }
}
