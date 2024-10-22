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
  cidr_block           = var.vpc_cidr
  provider             = aws.singapore
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dam-sg-vpc"
  }
}
resource "aws_vpc" "dam-ie-vpc" {
  cidr_block           = var.vpc_cidr
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
# Public Subnets
resource "aws_subnet" "dam-sg-subnet" {
  provider   = aws.singapore
  vpc_id     = aws_vpc.dam-sg-vpc.id
  cidr_block = var.sg_subnet_cidr

  tags = {
    Name = "dam-sg-subnet-1"
  }
}
resource "aws_subnet" "dam-ie-subnet" {
  provider   = aws.ireland
  vpc_id     = aws_vpc.dam-ie-vpc.id
  cidr_block = var.ie_subnet_cidr

  tags = {
    Name = "dam-ie-subnet-1"
  }
}
# Route Table
resource "aws_route_table" "dam-sg-rt" {
  vpc_id   = aws_vpc.dam-sg-vpc.id
  provider = aws.singapore

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = aws_internet_gateway.dam-sg-igw.id
  }

  tags = {
    Name = "dam-sg-rt"
  }
}
resource "aws_route_table" "dam-ie-rt" {
  vpc_id   = aws_vpc.dam-ie-vpc.id
  provider = aws.ireland

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = aws_internet_gateway.dam-ie-igw.id
  }

  tags = {
    Name = "dam-ie-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "dam-sg-rta" {
  subnet_id      = aws_subnet.dam-sg-subnet.id
  route_table_id = aws_route_table.dam-sg-rt.id
}
resource "aws_route_table_association" "dam-is-rta" {
  subnet_id      = aws_subnet.dam-ie-subnet.id
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
  subnet_id              = aws_subnet.dam-sg-subnet.id
  vpc_security_group_ids = [aws_security_group.dam-sg-sg.id]

  tags = {
    Name = "dam-sg-ec2"
  }
}
resource "aws_instance" "dam-ie-ec2" {
  provider               = aws.ireland
  ami                    = "ami-0d64bb532e0502c46"
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.dam-ie-subnet.id
  vpc_security_group_ids = [aws_security_group.dam-ie-sg.id]

  tags = {
    Name = "dam-ie-ec2"
  }
}

# RDS MySQL instance
resource "aws_db_instance" "mysql_db" {
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  identifier             = "dam-db"
  username               = var.db_username
  password               = var.db_password
  skip_final_snapshot    = true
  publicly_accessible    = false
  provider               = aws.singapore
  vpc_security_group_ids = [aws_security_group.rds-sg.id]
}

resource "aws_security_group" "rds-sg" {
  name        = "rds-sg"
  description = "Security group for RDS"
  vpc_id      = "dam-sg-vpc"
  provider    = aws.singapore

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.dam-sg-sg.id]
  }
}


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
  records        = ["10.0.2.1"]  # Replace with your Ireland endpoint IP
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
