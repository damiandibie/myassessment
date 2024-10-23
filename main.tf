
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
  name         = "damiand-lock-state"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}




# main.tf
# VPC
resource "aws_vpc" "dam-sg-vpc" {
  cidr_block           = var.vpc_cidr_sg
  provider             = aws.singapore
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dam-sg-vpc"
  }
}
resource "aws_vpc" "dam-ie-vpc" {
  cidr_block           = var.vpc_cidr_ie
  provider             = aws.ireland
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dam-ie-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "dam-sg-igw" {
  vpc_id   = aws_vpc.dam-sg-vpc.id
  provider = aws.singapore

  tags = {
    Name = "dam-sg-igw"
  }
}
resource "aws_internet_gateway" "dam-ie-igw" {
  vpc_id   = aws_vpc.dam-ie-vpc.id
  provider = aws.ireland

  tags = {
    Name = "dam-ie-igw"
  }
}
# Subnets
resource "aws_subnet" "dam-sg-pusubnet" {
  provider   = aws.singapore
  vpc_id     = aws_vpc.dam-sg-vpc.id
  cidr_block = var.sg_pusubnet_cidr

  tags = {
    Name = "dam-sg-subnet-pub"
  }
}
resource "aws_subnet" "dam-sg-prsubnet" {
  provider   = aws.singapore
  vpc_id     = aws_vpc.dam-sg-vpc.id
  cidr_block = var.sg_prsubnet_cidr

  tags = {
    Name = "dam-sg-subnet-pri"
  }
}
resource "aws_subnet" "dam-ie-pusubnet" {
  provider   = aws.ireland
  vpc_id     = aws_vpc.dam-ie-vpc.id
  cidr_block = var.ie_pusubnet_cidr

  tags = {
    Name = "dam-ie-subnet-pub"
  }
}
resource "aws_subnet" "dam-ie-prsubnet" {
  provider   = aws.ireland
  vpc_id     = aws_vpc.dam-ie-vpc.id
  cidr_block = var.ie_prsubnet_cidr

  tags = {
    Name = "dam-ie-subnet-pri"
  }
}
# Route Table
resource "aws_route_table" "dam-sg-rt" {
  vpc_id   = aws_vpc.dam-sg-vpc.id
  provider = aws.singapore
  route  {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dam-sg-igw.id
  }

  tags = {
    Name = "dam-sg-rt"
  }
}
resource "aws_route_table" "dam-ie-rt" {
  vpc_id   = aws_vpc.dam-ie-vpc.id
  provider = aws.ireland
  route  {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dam-ie-igw.id
  }

  tags = {
    Name = "dam-ie-rt"
  }
}




# Route Table Association
resource "aws_route_table_association" "dam-sg-rta" {
  provider       = aws.singapore
  subnet_id      = aws_subnet.dam-sg-pusubnet.id
  route_table_id = aws_route_table.dam-sg-rt.id
}
resource "aws_route_table_association" "dam-ie-rta" {
  provider       = aws.ireland
  subnet_id      = aws_subnet.dam-ie-pusubnet.id
  route_table_id = aws_route_table.dam-ie-rt.id
}

# Security Group
resource "aws_security_group" "dam-sg-sg" {
  name        = "dam-sg-sg"
  description = "Security group for EC2 instances in Singapore"
  vpc_id      = aws_vpc.dam-sg-vpc.id
  provider    = aws.singapore

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH from anywhere"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dam-sg-sg"
  }
}
resource "aws_security_group" "dam-ie-sg" {
  name        = "dam-ie-sg"
  description = "Security group for EC2 instances in Ireland"
  vpc_id      = aws_vpc.dam-ie-vpc.id
  provider    = aws.ireland

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH from anywhere"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dam-ie-sg"
  }
}



# EC2 Instances
resource "aws_instance" "dam-sg-ec2" {
  provider               = aws.singapore
  ami                    = "ami-047126e50991d067b"
  instance_type          = var.instance_type
  key_name               = "damian-sg"
  subnet_id              = aws_subnet.dam-sg-pusubnet.id
  vpc_security_group_ids = [aws_security_group.dam-sg-sg.id]

  tags = {
    Name = "dam-sg-ec2"
  }
}
resource "aws_instance" "dam-ie-ec2" {
  provider               = aws.ireland
  ami                    = "ami-0d64bb532e0502c46"
  instance_type          = var.instance_type
  key_name               = "damian-ie"
  subnet_id              = aws_subnet.dam-ie-pusubnet.id
  vpc_security_group_ids = [aws_security_group.dam-ie-sg.id]

  tags = {
    Name = "dam-ie-ec2"
  }
}

/*

# Auto Scaling configuration for peak users
resource "aws_autoscaling_group" "dam-sg-asg" {
  name                = "dam-sg-asg"
  vpc_zone_identifier = [aws_subnet.dam-sg-subnet.id]
  #target_group_arns   = [aws_lb_target_group.singapore-tg.arn]
  min_size            = 1
  max_size            = 10
  desired_capacity    = 2
  provider            = aws.singapore

  launch_template {
    id      = aws_launch_template.ec2-template-sg.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_group" "dam-ie-asg" {
  name                = "dam-ie-asg"
  vpc_zone_identifier = [aws_subnet.dam-ie-subnet.id]
  #target_group_arns   = [aws_lb_target_group.ireland-tg.arn]
  min_size            = 1
  max_size            = 5
  desired_capacity    = 1
  provider            = aws.ireland

  launch_template {
    id      = aws_launch_template.ec2-template-ie.id
    version = "$Latest"
  }
}

resource "aws_launch_template" "ec2-template-sg" {
  name_prefix   = "ec2-template"
  instance_type = "t2.micro"
  image_id      = "ami-047126e50991d067b"
  provider      = aws.singapore

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.dam-sg-sg.id]
  }
}

resource "aws_launch_template" "ec2-template-ie" {
  name_prefix   = "ec2-template"
  instance_type = "t2.micro"
  image_id      = "ami-0d64bb532e0502c46"
  provider      = aws.ireland

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.dam-ie-sg.id]
  }
}

resource "aws_autoscaling_policy" "damian-sg-policy" {
  name                   = "damian-sg-policy"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.dam-sg-asg.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}
resource "aws_autoscaling_policy" "damian-ie-policy" {
  name                   = "damian-ie-policy"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.dam-ie-asg.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}
# Create a private hosted zone associated with your VPC
resource "aws_route53_zone" "private" {
  name = "internal.routing"           # This is for internal reference only
  
  vpc {
    vpc_id = "vpc-0db0f10bf9072e869"  # Replace with your VPC ID
  }
  
  tags = {
    Environment = "dev"
    Name        = "internal-traffic-routing"
  }
}

# Create private record for Singapore endpoint (60% traffic)
resource "aws_route53_record" "singapore" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "endpoint.internal.routing"
  type    = "A"
  ttl     = 60
  
  weighted_routing_policy {
    weight = 60
  }

  set_identifier = "singapore"
  records        = ["10.0.1.1"]  # Replace with your Singapore endpoint IP
}

# Create private record for Ireland endpoint (30% traffic)
resource "aws_route53_record" "ireland" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "endpoint.internal.routing"
  type    = "A"
  ttl     = 60
  
  weighted_routing_policy {
    weight = 30
  }

  set_identifier = "ireland"
  records        = ["172.0.0.1"]  # Replace with your Ireland endpoint IP
}

# Create geolocation policy to block French IPs
resource "aws_route53_record" "france_restriction" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "endpoint.internal.routing"
  type    = "A"
  ttl     = 60
  
  geolocation_routing_policy {
    country = "FR"
  }

  set_identifier = "france"
  records        = ["0.0.0.0"]
}

# Default record for remaining 10% traffic
resource "aws_route53_record" "default" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "endpoint.internal.routing"
  type    = "A"
  ttl     = 60
  
  weighted_routing_policy {
    weight = 10
  }

  set_identifier = "default"
  records        = ["10.0.3.100"]  # Replace with your default endpoint IP
}

# Health check for Singapore endpoint
resource "aws_route53_health_check" "singapore" {
  ip_address        = "10.0.1.1"  # Replace with your Singapore IP
  port              = 80
  type              = "HTTP"
  resource_path     = "/health"
  failure_threshold = "3"
  request_interval  = "30"

  tags = {
    Name = "singapore-health-check"
  }
}

# Health check for Ireland endpoint
resource "aws_route53_health_check" "ireland" {
  ip_address        = "10.0.2.1"  # Replace with your Ireland IP
  port              = 80
  type              = "HTTP"
  resource_path     = "/health"
  failure_threshold = "3"
  request_interval  = "30"

  tags = {
    Name = "ireland-health-check"
  }
}
*/
/*
resource "aws_vpc" "damian-sg-vpc" {
  cidr_block = var.vpc_cidr
  provider   = aws.singapore
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "damian-sg-vpc"
  }
}

resource "aws_vpc" "damian-ie-vpc" {
  cidr_block = var.vpc_cidr
  provider   = aws.ireland
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "damian-ie-vpc"
  }
}

resource "aws_subnet" "damian-sg-subnet" {
  vpc_id     = aws_vpc.main-sg.id
  cidr_block = var.sg_subnet_cidr
  provider   = aws.singapore

  tags = {
    Name = "damian-sg-subnet"
  }
}

resource "aws_subnet" "damian-ie-subnet" {
  vpc_id     = aws_vpc.main-sg.id
  cidr_block = var.ie_subnet_cidr
  provider   = aws.ireland

  tags = {
    Name = "damian-ie-subnet"
  }
}


# EC2 instances
resource "aws_instance" "singapore_ec2" {
  provider      = aws.singapore
  ami           = "ami-047126e50991d067b"  # Amazon Linux 2 AMI in Singapore
  instance_type = "t3.medium"
  key_name      = "damian"
  
  tags = {
    Name = "Singapore-EC2"
  }
}

resource "aws_instance" "ireland_ec2" {
  provider      = aws.ireland
  ami           = "ami-0d64bb532e0502c46"  # Amazon Linux 2 AMI in Ireland
  instance_type = "t3.medium"
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
    id      = aws_launch_template.ec2_template-sg.id
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
    id      = aws_launch_template.ec2_template-ie.id
    version = "$Latest"
  }
}

resource "aws_launch_template" "ec2_template-sg" {
  name_prefix   = "ec2-template"
  instance_type = "t2.micro"
  image_id      = "ami-047126e50991d067b"  # Update with the correct AMI ID for your region

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2_sg.id]
  }
}

resource "aws_launch_template" "ec2_template-ie" {
  name_prefix   = "ec2-template"
  instance_type = "t2.micro"
  image_id      = "ami-0d64bb532e0502c46"  

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
*/
