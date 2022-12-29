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

#aws instance creation
resource "aws_instance" "web" {
  ami           = "ami-02045ebddb047018b"
  instance_type = "t2.micro"

  tags = {
    Name = "Terraform Ec2 instance"
  }
}