provider "aws" {
    region = "us-east-1"
}

# 1. create vpc
resource "aws_vpc" "wemerch" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "production"
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
    Name = "production"
  }
}
# todo: create private route table

# 4. create subnets
resource "aws_subnet" "wemerch_private_subnet1" {
    vpc_id = aws_vpc.wemerch.id
    cidr_block = "10.0.0.0/26"
    availability_zone = "us-east-1a"

    tags = {
        Name = "wemerch-private-subnet1"
    }
}

# 4. create subnets
resource "aws_subnet" "wemerch_private_subnet2" {
    vpc_id = aws_vpc.wemerch.id
    cidr_block = "10.0.0.64/26"
    availability_zone = "us-east-1b"

    tags = {
        Name = "wemerch-private-subnet2"
    }
}


resource "aws_subnet" "wemerch_public_subnet1" {
    vpc_id = aws_vpc.wemerch.id
    cidr_block = "10.0.0.128/26"
    availability_zone = "us-east-1a"

    tags = {
        Name = "wemerch-public-subnet1"
    }
}

resource "aws_subnet" "wemerch_public_subnet2" {
    vpc_id = aws_vpc.wemerch.id
    cidr_block = "10.0.0.192/26"
    availability_zone = "us-east-1b"

    tags = {
        Name = "wemerch-public-subnet2"
    }
}
# 5. associate subnet with route table
resource "aws_route_table_association" "wemerch_public_subnet_association1" {
  subnet_id      = aws_subnet.wemerch_public_subnet1.id
  route_table_id = aws_route_table.wemerch_public_route_table.id
}

resource "aws_route_table_association" "wemerch_public_subnet_association2" {
  subnet_id      = aws_subnet.wemerch_public_subnet2.id
  route_table_id = aws_route_table.wemerch_public_route_table.id
}

resource "aws_route_table_association" "wemerch_private_subnet_association1" {
  subnet_id      = aws_subnet.wemerch_private_subnet1.id
  route_table_id = aws_route_table.wemerch_public_route_table.id
}


resource "aws_route_table_association" "wemerch_private_subnet_association2" {
  subnet_id      = aws_subnet.wemerch_private_subnet1.id
  route_table_id = aws_route_table.wemerch_public_route_table.id
}