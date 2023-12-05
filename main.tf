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
    Name = "wemerch_public_route_table"
  }
}
resource "aws_route_table" "wemerch_private_route_table" {
  vpc_id = aws_vpc.wemerch.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.wemerch_nat_gateway.id
  }

  tags = {
    Name = "wemerch_private_route_table"
  }
}
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
  route_table_id = aws_route_table.wemerch_private_route_table.id
}


resource "aws_route_table_association" "wemerch_private_subnet_association2" {
  subnet_id      = aws_subnet.wemerch_private_subnet1.id
  route_table_id = aws_route_table.wemerch_private_route_table.id
}

resource "aws_security_group" "wemerch_db_security_group" {
  name        = "wemerch-db-security-group"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.wemerch.id

  ingress {
    description      = "PSQL from VPC"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    security_groups = [aws_security_group.wemerch_lambda_security_group.id ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_psql"
  }

}

resource "aws_eip" "wemerch_eip" {
  domain = "vpc"
}

# nat gateway to allow the lambda to communicate with outside servers
resource "aws_nat_gateway" "wemerch_nat_gateway" {
  allocation_id = aws_eip.wemerch_eip.id
  subnet_id     = aws_subnet.wemerch_public_subnet1.id
  tags = {
    Name = "wemerch-nat-gateway"
  }
}