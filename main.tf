provider "aws" {
  region = "us-east-1"
}

# Variables
locals {
  email       = "mangucletus@gmail.com"
  group_name  = "group7"
  cpu_threshold = 60
  alarm_period  = 360 # 6 minutes
}

# Create a VPC for the EC2 instance
resource "aws_vpc" "group7_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "${local.group_name}-vpc"
  }
}

# Create a subnet in the VPC
resource "aws_subnet" "group7_subnet" {
  vpc_id                  = aws_vpc.group7_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  
  tags = {
    Name = "${local.group_name}-subnet"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "group7_igw" {
  vpc_id = aws_vpc.group7_vpc.id
  
  tags = {
    Name = "${local.group_name}-igw"
  }
}

# Create a route table
resource "aws_route_table" "group7_rt" {
  vpc_id = aws_vpc.group7_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.group7_igw.id
  }
  
  tags = {
    Name = "${local.group_name}-rt"
  }
}

# Associate route table with subnet
resource "aws_route_table_association" "group7_rt_assoc" {
  subnet_id      = aws_subnet.group7_subnet.id
  route_table_id = aws_route_table.group7_rt.id
}

# Create a security group
resource "aws_security_group" "group7_sg" {
  name        = "${local.group_name}-sg"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = aws_vpc.group7_vpc.id
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = {
    Name = "${local.group_name}-sg"
  }
}

# Create an IAM role for the EC2 instance
resource "aws_iam_role" "group7_ec2_role" {
  name = "${local.group_name}-ec2-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach CloudWatch full access policy to the role
resource "aws_iam_role_policy_attachment" "cloudwatch_policy_attachment" {
  role       = aws_iam_role.group7_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

# Create an instance profile for the EC2 instance
resource "aws_iam_instance_profile" "group7_instance_profile" {
  name = "${local.group_name}-instance-profile"
  role = aws_iam_role.group7_ec2_role.name
}

# Create an EC2 instance
resource "aws_instance" "group7_instance" {
  ami                    = "ami-0953476d60561c955" # Amazon Linux 2 AMI (HVM), SSD Volume Type
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.group7_subnet.id
  vpc_security_group_ids = [aws_security_group.group7_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.group7_instance_profile.name
  
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y stress
    echo "*/5 * * * * stress --cpu 1 --timeout 300" | crontab -
  EOF
  
  tags = {
    Name = "${local.group_name}-instance"
  }
}

# Create an SNS topic
resource "aws_sns_topic" "group7_sns_topic" {
  name = "${local.group_name}-cpu-alarm-topic"
}

# Subscribe email to the SNS topic
resource "aws_sns_topic_subscription" "group7_email_subscription" {
  topic_arn = aws_sns_topic.group7_sns_topic.arn
  protocol  = "email"
  endpoint  = local.email
}

# Create a CloudWatch alarm for CPU utilization
resource "aws_cloudwatch_metric_alarm" "group7_cpu_alarm" {
  alarm_name          = "${local.group_name}-cpu-utilization-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = local.alarm_period
  statistic           = "Average"
  threshold           = local.cpu_threshold
  alarm_description   = "This metric monitors ec2 cpu utilization"
  
  dimensions = {
    InstanceId = aws_instance.group7_instance.id
  }
  
  alarm_actions = [aws_sns_topic.group7_sns_topic.arn]
  ok_actions    = [aws_sns_topic.group7_sns_topic.arn]
}

# Outputs
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.group7_instance.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.group7_instance.public_ip
}

output "cloudwatch_alarm_name" {
  description = "Name of the CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.group7_cpu_alarm.alarm_name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic"
  value       = aws_sns_topic.group7_sns_topic.arn
}