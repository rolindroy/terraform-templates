variable "aws_access_key" {}

variable "aws_secret_key" {}

variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_network" {
  default = "10.0"
}

variable "ec2_ami" {
  default = "ami-97785bed"
}
