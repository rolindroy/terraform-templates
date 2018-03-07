provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

## AWS KeyPair
resource "aws_key_pair" "terraform_key" {
  key_name   = "terraform-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDllVejIyQpF31DzmGRhJEZcAaDRv82i7E/BkamG/nAVekxug81VYUgKstC0iEzhGGid2Mrtk0WFso8V146L4tZR3+20mKhaa4Ng/DNCT3BmEnTYhk6Bq+p8Z1v11dRJCOPbBQ15VNzMcBphbkxePXITsYcvZQ3AB0PCzTH9xtrkkFK06IueFDaUCBs8Yp5gv9xPR7Me2/+QLTCkziwc/JoB91vAViGbLHQ9yEzPzOw2n2tzJkQYLgCnLX919X6+OSp31v97V6mmh/8oyb1woNa1e5UXEDc8yTNsrBaILsBasUFSF5nhKJUmdvffrcSgs5c9AkeiWEwUz/o3bhKSL4pr9OH0fvBXf1g1bL6wmfO9gsVxxX9Wvuy7pjWPUncjZhoeMN/BvEXDQFWPF3x7fIgM3Fl9RfOmYVMxsO52WmiKb7hz3EQLbzRffyfIaA9iXRnq9GH0ccGEKFJp+FAjmujSOzj9kxLgnNH8JSi4o7/931aUZ6K0qA4vqsvk8Uw5pmkPyWdllpm9PZ/M379DjOzWXiePVsRudDqBN9S/PrqJR3cR9ACNPs+SJngxsU7Fqpvr2Efh+2wZqvACZUifH0vt6NrPzPBkKTvOZJcUa/ZqQTG0y1ClVQSvjEUmmg++AbAR08ZtVZnXzfEMNsdbc//TrSTT7CSWSuKZMjQCwLKzw== hello@rolindroy"
}

## AWS VPC
resource "aws_vpc" "terraform_vpc" {
  cidr_block           = "${var.vpc_network}.0.0/16"
  enable_dns_hostnames = true
  tags {
    Name = "terraform"
  }
}

## AWS Subnet_1
resource "aws_subnet" "subnet_1" {
  vpc_id            = "${aws_vpc.terraform_vpc.id}"
  cidr_block        = "${var.vpc_network}.1.0/24"
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags {
    Name = "subnet-1"
  }
}

## AWS Subnet_2
resource "aws_subnet" "subnet_2" {
  vpc_id            = "${aws_vpc.terraform_vpc.id}"
  cidr_block        = "${var.vpc_network}.2.0/24"
  availability_zone = "${var.aws_region}b"
  tags {
    Name = "subnet-2"
  }
}

## AWS Internet gateway
resource "aws_internet_gateway" "terrafom_gw" {
  vpc_id = "${aws_vpc.terraform_vpc.id}"
  tags {
    Name = "terraform_gw"
  }
}

## Update Route Table
resource "aws_default_route_table" "terraform_rt" {
  default_route_table_id = "${aws_vpc.terraform_vpc.default_route_table_id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.terrafom_gw.id}"
  }
  tags {
    Name = "terraform_default_rt"
  }
}

## AWS Public Subnet
resource "aws_route_table_association" "terraform_public_subnet_1" {
	subnet_id = "${aws_subnet.subnet_1.id}"
	route_table_id = "${aws_vpc.terraform_vpc.default_route_table_id}"
}

## AWS aws_security_group
resource "aws_security_group" "terrafrom_sg_app" {
  name        = "terraform_sg_app"
  description = "Allow all egress traffic and ingress 22,80"
  vpc_id      = "${aws_vpc.terraform_vpc.id}"
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
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

## AWS instance
resource "aws_instance" "web" {
  ami           = "${var.ec2_ami}"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.subnet_1.id}"
  key_name = "${aws_key_pair.terraform_key.key_name}"
  vpc_security_group_ids = [
    "${aws_security_group.terrafrom_sg_app.id}"
  ]
  user_data = <<-EOF
      #!/bin/bash
      yum install httpd
      systemctl start httpd &
      EOF
  tags {
    Name = "terrafrom-app"
  }
}
