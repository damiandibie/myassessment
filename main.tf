#Create S3 bucket
resource "aws_s3_bucket" "damiand-s3" {
  bucket = var.damiand-s3
  
}

resource "aws_s3_bucket_versioning" "damiand-ver" {
  bucket = aws_s3_bucket.damiand-s3.id
  versioning_configuration {
    status = "Enabled"
  }
}


#Create dynamoDB
resource "aws_dynamodb_table" "basics-dynamodb-table" {
  name           = "damiand-lock-state"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# EC2 instances
resource "aws_instance" "singapore_ec2" {
  provider      = aws.singapore
  ami           = "ami-047126e50991d067b"  # Amazon Linux 2 AMI in Singapore
  instance_type = "t2.micro"
  key_name      = "damian"
  
  tags = {
    Name = "Singapore-EC2"
  }
}

resource "aws_instance" "ireland_ec2" {
  provider      = aws.ireland
  ami           = "ami-0d64bb532e0502c46"  # Amazon Linux 2 AMI in Ireland
  instance_type = "t2.micro"
  key_name      = "damian"
  
  tags = {
    Name = "Ireland-EC2"
  }
}

# Application Load Balancer
resource "aws_lb" "global_alb" {
  name               = "global-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default_subnets.ids

  enable_deletion_protection = false
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.global_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.singapore_tg.arn
        weight = 60
      }
      target_group {
        arn    = aws_lb_target_group.ireland_tg.arn
        weight = 30
      }
    }
  }
}

resource "aws_lb_target_group" "singapore_tg" {
  name     = "singapore-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}

resource "aws_lb_target_group" "ireland_tg" {
  name     = "ireland-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}

resource "aws_lb_target_group_attachment" "singapore_attachment" {
  target_group_arn = aws_lb_target_group.singapore_tg.arn
  target_id        = aws_instance.singapore_ec2.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "ireland_attachment" {
  target_group_arn = aws_lb_target_group.ireland_tg.arn
  target_id        = aws_instance.ireland_ec2.id
  port             = 80
}

# RDS MySQL instance
resource "aws_db_instance" "mysql_db" {
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_type         = "gp2"
  identifier           = "mydb"
  username             = var.db_username
  password             = var.db_password  # Change this to a secure password
  skip_final_snapshot  = true
  publicly_accessible  = false
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
}

# Security Groups
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = data.aws_vpc.default.id

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

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Security group for EC2 instances"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Security group for RDS"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }
}

# Data sources for default VPC and subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# WAF WebACL for France restriction
resource "aws_wafv2_web_acl" "france_restriction" {
  name  = "france-restriction"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "block-france"
    priority = 1

    action {
      block {}
    }

    statement {
      geo_match_statement {
        country_codes = ["FR"]
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "FranceBlockRule"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "FranceRestrictionWebACL"
    sampled_requests_enabled   = true
  }
}

# Associate WAF WebACL with ALB
resource "aws_wafv2_web_acl_association" "alb_waf_association" {
  resource_arn = aws_lb.global_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.france_restriction.arn
}

# Auto Scaling configuration for peak users
resource "aws_autoscaling_group" "singapore_asg" {
  name                = "singapore-asg"
  vpc_zone_identifier = data.aws_subnets.default_subnets.ids
  target_group_arns   = [aws_lb_target_group.singapore_tg.arn]
  min_size            = 1
  max_size            = 10
  desired_capacity    = 2

  launch_template {
    id      = aws_launch_template.ec2_template.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_group" "ireland_asg" {
  name                = "ireland-asg"
  vpc_zone_identifier = data.aws_subnets.default_subnets.ids
  target_group_arns   = [aws_lb_target_group.ireland_tg.arn]
  min_size            = 1
  max_size            = 5
  desired_capacity    = 1

  launch_template {
    id      = aws_launch_template.ec2_template.id
    version = "$Latest"
  }
}

resource "aws_launch_template" "ec2_template" {
  name_prefix   = "ec2-template"
  instance_type = "t2.micro"
  image_id      = "ami-047126e50991d067b"  # Update with the correct AMI ID for your region

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2_sg.id]
  }
}

resource "aws_autoscaling_policy" "target_tracking_policy" {
  name                   = "target-tracking-policy"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.singapore_asg.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}
