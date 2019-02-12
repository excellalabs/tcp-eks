module "private_subnet" {
  source = "../subnet"

  name               = "${var.name}-private-subnet"
  environment        = "${var.environment}"
  vpc_id             = "${var.vpc_id}"
  cidrs              = "${var.private_subnet_cidrs}"
  availability_zones = "${var.availability_zones}"
  aws_email          = "${var.aws_email}"
}

module "public_subnet" {
  source = "../subnet"

  name               = "${var.name}-public-subnet"
  environment        = "${var.environment}"
  vpc_id             = "${var.vpc_id}"
  cidrs              = "${var.public_subnet_cidrs}"
  availability_zones = "${var.availability_zones}"
  aws_email          = "${var.aws_email}"
}

# Using the AWS NAT Gateway service instead of a nat instance, it's more expensive but easier
# See comparison http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/vpc-nat-comparison.html

resource "aws_nat_gateway" "nat" {
  allocation_id = "${element(aws_eip.nat.*.id, count.index)}"
  subnet_id     = "${element(module.public_subnet.ids, count.index)}"
  count         = "${length(var.public_subnet_cidrs)}"
  tags {
    Name        = "${var.name}-nat-gateway"
    Project     = "${var.name}"
    Creator     = "${var.aws_email}"
    Environment = "${var.environment}"
  }
}

resource "aws_eip" "nat" {
  vpc   = true
  count = "${length(var.public_subnet_cidrs)}"
}

resource "aws_route" "public_igw_route" {
  count                  = "${length(var.public_subnet_cidrs)}"
  route_table_id         = "${element(module.public_subnet.route_table_ids, count.index)}"
  gateway_id             = "${var.vpc_igw}"
  destination_cidr_block = "${var.destination_cidr_block}"
}

resource "aws_route" "private_nat_route" {
  count                  = "${length(var.private_subnet_cidrs)}"
  route_table_id         = "${element(module.private_subnet.route_table_ids, count.index)}"
  nat_gateway_id         = "${element(aws_nat_gateway.nat.*.id, count.index)}"
  destination_cidr_block = "${var.destination_cidr_block}"
}

# Creating a NAT Gateway takes some time. Some services need the internet (NAT Gateway) before proceeding. 
# Therefore we need a way to depend on the NAT Gateway in Terraform and wait until is finished. 
# Currently Terraform does not allow module dependency to wait on.
# Therefore we use a workaround described here: https://github.com/hashicorp/terraform/issues/1178#issuecomment-207369534

resource "null_resource" "dummy_dependency" {
  depends_on = ["aws_nat_gateway.nat"]
}
