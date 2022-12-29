terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-southeast-1"
}
 

#VPC
 resource "aws_vpc" "teraVPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "VPC created by terraform"
  }
} 

#Subnet - public 
resource "aws_subnet" "sub_pub" {
  vpc_id     = aws_vpc.teraVPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "TeraVPC-Sub-pub"
  }
}

#Subnet - Private
resource "aws_subnet" "sub_pvt" {
  vpc_id     = aws_vpc.teraVPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-southeast-1b"

  tags = {
    Name = "TeraVPC-Sub-pvt"
  }
}

#Internet gateway
resource "aws_internet_gateway" "teraVPC_IGW" {
  vpc_id = aws_vpc.teraVPC.id
  tags = {
    Name = "TeraVPC-Internet gateway"
  }
}

#Route table - Public
resource "aws_route_table" "RT_pub" {
  vpc_id = aws_vpc.teraVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.teraVPC_IGW.id
  }
  tags = {
    Name = "teraVPC RT-Pub"
  }
} 

#Route table association public 
resource "aws_route_table_association" "RTA_public" {
  subnet_id      = aws_subnet.sub_pub.id
  route_table_id = aws_route_table.RT_pub.id
}


#Nat gateway for private subnet
resource "aws_nat_gateway" "NAT_sub" {
  allocation_id = aws_eip.Eip_public_subnet.id
  subnet_id     = aws_subnet.sub_pub.id

  tags = {
    Name = "teraVPC NAT"
  }
}

#Route table - Private
resource "aws_route_table" "RT_pvt" {
  vpc_id = aws_vpc.teraVPC.id

  route {
    cidr_block = "0.0.0.0/0"
   gateway_id = aws_nat_gateway.NAT_sub.id
  }
  tags = {
    Name = "teraVPC RT-pvt"
  }
} 

#Route table association private 
resource "aws_route_table_association" "RTA_private" {
  subnet_id      = aws_subnet.sub_pvt.id
  route_table_id = aws_route_table.RT_pvt.id
}

#Security group public 
resource "aws_security_group" "secgroup_pub" {
  name        = "Public security group"
  description = "For web server"
  vpc_id      = aws_vpc.teraVPC.id

  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.teraVPC.cidr_block]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "public security group_webserver"
  }
}

#Security group private 
resource "aws_security_group" "secgroup_pvt" {
  name        = "Private security group"
  description = "For app server"
  vpc_id      = aws_vpc.teraVPC.id

  ingress {
    description      = "source from public server"
    from_port        = 80
    to_port          = 443
    protocol         = "tcp"
   security_groups   = [aws_security_group.secgroup_pub.id]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "private security group security group_webserver"
  }
}

#Elastic ip
resource "aws_eip" "Eip_public_subnet" {
  vpc      = true
}




#aws instance creation
resource "aws_instance" "web_server" {
  ami           = "ami-02045ebddb047018b"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["$(aws_security_group.secgroup_pub.id)"]
  subnet_id = aws_subnet.sub_pub.id
  associate_public_ip_address = true

  tags = {
    Name = "Terraform Webserver"
  }
}

resource "aws_instance" "App_server" {
  ami           = "ami-02045ebddb047018b"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["$(aws_security_group.secgroup_pvt.id)"]
  subnet_id = aws_subnet.sub_pvt.id

  tags = {
    Name = "Terraform App server"
  }
}