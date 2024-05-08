###############################
# Provider
###############################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}


###############################
# VPC, subnet
###############################

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-1a"
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-southeast-1a"
}

resource "aws_security_group" "web_server_sg" {
  name   = "web_server_security_group"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

###############################
# Filter AMI id
###############################
data "aws_ami" "ami_src" {
  most_recent = true

  owners = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-*"]
  }
}

###############################
# EC2
###############################

resource "null_resource" "keypair" {
  provisioner "local-exec" {
    on_failure = fail
    command    = <<EOF
    #!/bin/bash
    aws ec2 create-key-pair \
      --key-name myec2-keypair \
      --key-type rsa \
      --key-format pem \
      --query "KeyMaterial" \
      --output text > myec2-keypair.pem && \
      chmod 400 myec2-keypair.pem
    EOF
  }
}

resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.ami_src.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.web_server_sg.id]
  associate_public_ip_address = true
  key_name                    = "myec2-keypair"
  depends_on = [ null_resource.keypair ]

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ./myec2-keypair.pem && aws ec2 delete-key-pair --key-name myec2-keypair"
  }

  user_data = file("./nginx.sh")
}

output "public_ip_ec2" {
  value = aws_instance.web_server.public_ip
}
