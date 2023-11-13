provider "aws" {
    region = "us-east-1"
    access_key = ""
    secret_key = ""
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
# 3. create route table
resource "aws_route_table" "wemerch_rt" {
  vpc_id = aws_vpc.wemerch.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wemerch.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_egress_only_internet_gateway.example.id
  }

  tags = {
    Name = "development"
  }
}
# 4. create subnet
resource "aws_subnet" "wemerch_subnet_1" {
    vpc_id = aws_vpc.wemerch.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"

    tags = {
        Name = "development"
    }
}
# 5. associate subnet with route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.wemerch_subnet_1.id
  route_table_id = aws_route_table.wemerch_rt.id
}

# 6. create security group to allow port 80, 443
resource "aws_security_group" "allow_web_traffic" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.wemerch.id

  ingress {
    description      = "HTTPS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = " "
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}
# 7. create network interface with an ip in subnet from #4
resource "aws_network_interface" "wemerch_network_interface" {
  subnet_id       = aws_subnet.wemerch_subnet_1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web_traffic.id]

  attachment {
    instance     = aws_instance.test.id
    device_index = 1
  }
}
# 8. assign an elastic IP to network interface so lambda can talk to square
resource "aws_eip" "one" {
    domain = "vpc"
    network_interface = aws_network_interface.wemerch_network_interface.id
    associate_with_private_ip = "10.0.1.50"
}
# 9. create lambda/ api gateway server 
# 10. where do i bring in the db? (do not create new one because paying for dedicated host)
# 11. does terraform manage the s3 bucket where the frontend is hosted