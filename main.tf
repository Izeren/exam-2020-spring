data "aws_availability_zones" "all" {}

provider "aws" {
  region = "eu-west-1"
}

resource "aws_security_group" "instance" {
  name = "terrafrom-example-instance"
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "instance1" {
  ami                    = "ami-f90a4880"
  instance_type          = "t2.micro"
  user_data              = <<-EOF
		#!/bin/bash
		echo "Hello, World 1" > index.html
		nohup busybox httpd -f -p var.server_port &
	EOF 
  vpc_security_group_ids = [aws_security_group.instance.id]
  tags = {
    Name = "terraform-example"
  }
}

resource "aws_instance" "instance2" {
  ami                    = "ami-f90a4880"
  instance_type          = "t2.micro"
  user_data              = <<-EOF
		#!/bin/bash
		echo "Hello, World 2" > index.html
		nohup busybox httpd -f -p var.server_port &
	EOF 
  vpc_security_group_ids = [aws_security_group.instance.id]
  tags = {
    Name = "terraform-example"
  }
}

variable "server_port" {
  description = "Server port for HTTP requests"
  default     = 80
}

resource "aws_elb" "example" {
  name               = "terraform-elb-example"
  availability_zones = data.aws_availability_zones.all.names
  security_groups    = [aws_security_group.elb.id]
  instances = [aws_instance.instance1.id, aws_instance.instance2.id]

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:${var.server_port}/"
  }

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = "${var.server_port}"
    instance_protocol = "http"
  }
}

resource "aws_security_group" "elb" {
  name = "terraform-example-elb"

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

output "elb_dns_name" {
  value = "${aws_elb.example.dns_name}"
}
