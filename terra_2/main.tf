provider "aws" {
    region ="us-east-1"
}
# Creating VPC
resource "aws_vpc" "testvpc" {
  cidr_block       = "${var.vpc_cidr}"
  instance_tenancy = "default"

  tags = {
    Name = "testvpc"
  }
}
# Creating Internet Gateway 
resource "aws_internet_gateway" "demogateway" {
  vpc_id = "${aws_vpc.testvpc.id}"
  tags = {
    Name = "test-igw"
  }
}
# Creating Route Table
resource "aws_route_table" "route" {
  vpc_id = "${aws_vpc.testvpc.id}"
route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.demogateway.id}"
  }
tags = {
      Name = "Route-table1"
  }
}
# Creating 1st web subnet 
resource "aws_subnet" "public-subnet-1" {
  vpc_id                  = "${aws_vpc.testvpc.id}"
  cidr_block             = "${var.subnet_cidr}"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
tags = {
  Name = "subnet1"
}
}
# Associating Route Table
resource "aws_route_table_association" "rt1" {
  subnet_id = "${aws_subnet.public-subnet-1.id}"
  route_table_id = "${aws_route_table.route.id}"
}
# Creating Security Group 
resource "aws_security_group" "test-security" {
  vpc_id = "${aws_vpc.testvpc.id}"
# Inbound Rules
# HTTP access from anywhere
ingress {
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
# HTTPS access from anywhere
ingress {
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
# SSH access from anywhere
ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
# Outbound Rules
# Internet access to anywhere
egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
tags = {
  Name = "Web-SG"
}
}
resource "aws_network_interface" "project_interface" {
subnet_id = aws_subnet.public-subnet-1.id
private_ips = ["10.0.1.8"]
tags = {
name = "MY_NETWORK_INTERFACE"
}
}
resource "aws_eip" "my_ip" {
vpc = true
}
resource "aws_eip_association" "my_eip_association" {
  network_interface_id = aws_network_interface.project_interface.id
  allocation_id = aws_eip.my_ip.id
}
# Create Ubuntu server and install/enable apache2
resource "aws_instance" "ubuntu_image" {
    ami                    = "ami-04b70fa74e45c3917"
    instance_type          = "t2.micro"
    subnet_id              = aws_subnet.public-subnet-1.id
    vpc_security_group_ids = [aws_security_group.test-security.id]
    associate_public_ip_address = true  # Enable auto-assigning public IP
    user_data = <<-EOF
                 #!/bin/bash
                 apt-get update
                 apt-get install -y apache2
                 systemctl enable apache2
                 systemctl start apache2
                 EOF
}

resource "aws_s3_bucket" "s3_bucket" {
    
    bucket = "s3-backend-john"
    acl = "private"
}
resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
  name = "terraform-task"
  hash_key = "LockID"
  read_capacity = 20
  write_capacity = 20
 
  attribute {
    name = "LockID"
    type = "S"
  }
}
terraform {
  backend "s3" {
    bucket = "s3-backend-john"
    dynamodb_table = "terraform-task"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
