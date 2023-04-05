
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}


# resource "aws_instance" "web" {
#   ami           = "ami-02eb7a4783e7e9317"
#   instance_type = "t2.micro"
#   key_name = "linux-os-key"

#   tags = {
#     Name = "Terraform-demo-instanc-1234"
#     technical = "Amol"
#     dept = ""
#     Infra = "Terraform"
#   }
# }


# Creating the VPC 

resource "aws_vpc" "webapp-vpc" {
  cidr_block       = "10.10.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Webapp-VPC"
  }
}


#creating subnet

resource "aws_subnet" "webapp-subnet-1a" {
  vpc_id     = aws_vpc.webapp-vpc.id
  cidr_block = "10.10.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Webapp-subnet-1A"
  }
}


resource "aws_subnet" "webapp-subnet-1b" {
  vpc_id     = aws_vpc.webapp-vpc.id
  cidr_block = "10.10.1.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "Webapp-subnet-1B"
  }
}


resource "aws_subnet" "webapp-subnet-1c" {
  vpc_id     = aws_vpc.webapp-vpc.id
  cidr_block = "10.10.2.0/24"
  availability_zone = "ap-south-1c"
  
  tags = {
    Name = "Webapp-subnet-1C"
  }
}



resource "aws_instance" "webapp-01" {
  ami           = "ami-0ad37e9b1d9b2b4c6"
  instance_type = "t2.micro"
  key_name = aws_key_pair.webapp-key-pair.id
  #key_name = "linux-os-key"
  subnet_id = aws_subnet.webapp-subnet-1a.id
  #associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  user_data = <<EOF
   #!/bin/bash

   sudo apt-get update
   mkdir /root/dir1
   

   EOF

  tags = {
    Name = "Webapp-01"
  }
}


resource "aws_instance" "webapp-02" {
  ami           = "ami-0ad37e9b1d9b2b4c6"
  instance_type = "t2.micro"
  key_name = aws_key_pair.webapp-key-pair.id
  #key_name = "linux-os-key"
  subnet_id = aws_subnet.webapp-subnet-1b.id
  #associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  user_data = <<EOF
   #!/bin/bash

   sudo apt-get update
   mkdir /root/dir1


   EOF

  tags = {
    Name = "Webapp-02"
  }
}

resource "aws_key_pair" "webapp-key-pair" {
  key_name   = "webapp-key-pair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDM0Fqft1CpqlHV6z6rEqKDr0uIWDaBNu/ftS74G9kwnBKXieqOtlIUVtnrJlffze7gBfIT6QJHqfV8G2zGHXipTKTXX+M5FDWeA0IEWU/DE2LKNfZVdR2Y211BYAkxlB1P/zXy1Eo8oPc9cShUk2d/j2cehs7mGpSZQ8cQM5UIZM6Or+NdTIvv+yxUgOm/xDFd5sWMnW/8hjAeAGYh7ndejvujzq+bXg5I8cigpzYe/izmQMdMP3B3U5BDaO+1IABXeaSbzIw1P1ieURWOhOS3JIyA3rt/D/PNrfVHtq5xOmJIpNRg1qHDLp1Deh0LF5y+sFzOWAdHRE08QM/P7lSwBnswP+/Q5RI0k+ouYEcHjePxTdYCEv1AJ92xk11YrYBDOd0qt8HX7oHzpgfEZPYGQWiIVjuhxirPOa0MZrFY0tG4Kbwsw5zT8IqFKK6O4S5Eb8KH+HoB9JhTIuhg4IalKu8Oa71H98D6F21d03ole+C6tJCRPr18k8xT1qa3mI0= Amol@DESKTOP-2MVQBON"
}

# Internet GW

resource "aws_internet_gateway" "webapp-IGW" {
  vpc_id = aws_vpc.webapp-vpc.id

  tags = {
    Name = "Webapp-IGW"
  }
}

# Route Table

resource "aws_route_table" "webapp-RT" {
  vpc_id = aws_vpc.webapp-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.webapp-IGW.id
  }

  tags = {
    Name = "Webapp-RT"
  }
}

resource "aws_route_table_association" "webapp-RT-asso-01" {
  subnet_id      = aws_subnet.webapp-subnet-1a.id
  route_table_id = aws_route_table.webapp-RT.id
}


resource "aws_route_table_association" "webapp-RT-asso-02" {
  subnet_id      = aws_subnet.webapp-subnet-1b.id
  route_table_id = aws_route_table.webapp-RT.id
}

# Security Group

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.webapp-vpc.id

  ingress {
    description      = "ssh from anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  
  ingress {
    description      = "http from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ALLOW_SSH"
  }
}


#target group creation

resource "aws_lb_target_group" "webapp-TG" {
  name     = "webapp-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.webapp-vpc.id
}

resource "aws_lb_target_group_attachment" "webapp-TG-attach-01" {
  target_group_arn = aws_lb_target_group.webapp-TG.arn
  target_id        = aws_instance.webapp-01.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "webapp-TG-attach-02" {
  target_group_arn = aws_lb_target_group.webapp-TG.arn
  target_id        = aws_instance.webapp-02.id
  port             = 80
}

# LB Listener

resource "aws_lb_listener" "webapp-listener" {
  load_balancer_arn = aws_lb.webapp-LB.arn
  port              = "80"
  protocol          = "HTTP"
 
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp-TG.arn
  }
}

#load balancer

resource "aws_lb" "webapp-LB" {
  name               = "Webapp-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_ssh.id]
  subnets            = [aws_subnet.webapp-subnet-1a.id,aws_subnet.webapp-subnet-1b.id,aws_subnet.webapp-subnet-1c.id]


  tags = {
    Environment = "production"
  }
}