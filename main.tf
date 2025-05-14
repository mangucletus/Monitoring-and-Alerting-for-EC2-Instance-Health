provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "group7_key" {
  key_name   = "group7-key"
  public_key = file("~/.ssh/id_rsa.pub") # Make sure this exists or replace with your public key
}

resource "aws_security_group" "group7_sg" {
  name        = "group7-sg"
  description = "Allow SSH"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # SSH access (adjust as needed)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_instance" "group7_instance" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.group7_key.key_name
  vpc_security_group_ids      = [aws_security_group.group7_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "group7-ec2-instance"
  }
}

resource "aws_cloudwatch_metric_alarm" "group7_cpu_alarm" {
  alarm_name                = "group7-cpu-alarm"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 180
  statistic                 = "Average"
  threshold                 = 60
  alarm_description         = "This alarm monitors CPU utilization and alerts if above 60% for 6 minutes"
  alarm_actions             = [aws_sns_topic.group7_sns_topic.arn]
  ok_actions                = [aws_sns_topic.group7_sns_topic.arn]
  dimensions = {
    InstanceId = aws_instance.group7_instance.id
  }
}

resource "aws_sns_topic" "group7_sns_topic" {
  name = "group7-sns-topic"
}

resource "aws_sns_topic_subscription" "group7_email_sub" {
  topic_arn = aws_sns_topic.group7_sns_topic.arn
  protocol  = "email"
  endpoint  = "mangucletus@gmail.com"
}
