provider "aws" {
    region = "us-east-1"
}

# 1. create vpc
resource "aws_vpc" "wemerch" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "development"
    }
}
# 2. create internet gateway
resource "aws_internet_gateway" "wemerch" {
    vpc_id = aws_vpc.wemerch.id
}
# 3. create 2 route tables (public and private)
resource "aws_route_table" "wemerch_public_route_table" {
  vpc_id = aws_vpc.wemerch.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wemerch.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.wemerch.id
  }

  tags = {
    Name = "development"
  }
}
# todo: create private route table

# 4. create subnets
resource "aws_subnet" "wemerch_private_subnet" {
    vpc_id = aws_vpc.wemerch.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"

    tags = {
        Name = "wemerch-private-subnet"
    }
}

resource "aws_subnet" "wemerch_public_subnet" {
    vpc_id = aws_vpc.wemerch.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"

    tags = {
        Name = "wemerch-public-subnet"
    }
}
# 5. associate subnet with route table
resource "aws_route_table_association" "wemerch_pulic_subnet_association" {
  subnet_id      = aws_subnet.wemerch_public_subnet.id
  route_table_id = aws_route_table.wemerch_public_route_table.id
}

# todo this should be associated to a private route table
resource "aws_route_table_association" "wemerch_private_subnet_association" {
  subnet_id      = aws_subnet.wemerch_private_subnet.id
  route_table_id = aws_route_table.wemerch_public_route_table.id
}