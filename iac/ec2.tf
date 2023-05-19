resource "aws_vpc" "main" {
  cidr_block = "172.31.0.0/16"
  tags = {
    "Name" = "main"
  }
}

resource "aws_subnet" "default" {
  vpc_id = aws_vpc.main.id
  cidr_block = "172.31.80.0/20"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "default2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "172.31.32.0/20"
  map_public_ip_on_launch = true
}

resource "aws_security_group" "allow_http" {
  egress      = [
      {
          protocol         = "-1"
          cidr_blocks      = [ "0.0.0.0/0" ]
          description      = ""
          from_port        = 0
          to_port          = 0
          ipv6_cidr_blocks = []
          prefix_list_ids  = []
          security_groups  = []
          self             = false
      },
  ]
  ingress     = [
      {
          cidr_blocks      = [ "0.0.0.0/0" ]
          description      = ""
          from_port        = 22
          ipv6_cidr_blocks = []
          prefix_list_ids  = []
          protocol         = "tcp"
          security_groups  = []
          self             = false
          to_port          = 22
      },
      {
          cidr_blocks      = [
              "0.0.0.0/0",
          ]
          description      = ""
          from_port        = 80
          ipv6_cidr_blocks = []
          prefix_list_ids  = []
          protocol         = "tcp"
          security_groups  = []
          self             = false
          to_port          = 80
      },
  ]
}

resource "aws_iam_role" "nginx_role" {
  name = "NginxRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = ""
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_iam_instance_profile" "nginx_instance_profile" {
  name = "NginxInstanceRole"
  role = aws_iam_role.nginx_role.name
}

resource "aws_launch_template" "nginx_template" { 
  name_prefix = "NginxProxyCache"
  image_id    = data.aws_ami.al2023.id
  instance_type = "t2.micro"
  key_name = "MyKeyPair"

  iam_instance_profile {
    name = aws_iam_instance_profile.nginx_instance_profile.name
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "NginxProxyCache"
    }
  }
}

resource "aws_autoscaling_group" "nginx_asg" {
  desired_capacity   = 4
  max_size           = 4
  min_size           = 4
  vpc_zone_identifier = [aws_subnet.default.id, aws_subnet.default2.id]

  launch_template {
    id      = aws_launch_template.nginx_template.id
    version = "$Latest"
  }
}

