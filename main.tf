#Create S3 bucket
resource "aws_s3_bucket" "damian-s3" {
  bucket = var.damian-s3
  
}

resource "aws_s3_bucket_versioning" "damian-ver" {
  bucket = aws_s3_bucket.damian-s3.id
  versioning_configuration {
    status = "Enabled"
  }
}


#Create dynamoDB
resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = "damian-lock-state"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_vpc" "main-sg" {
  cidr_block = var.vpc_cidr
  provider   = aws.singapore
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "main-sg-vpc"
  }
}
resource "aws_vpc" "main-ie" {
  cidr_block = var.vpc_cidr
  provider   = aws.ireland
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "main-ie-vpc"
  }
}

# Create Singapore subnet
resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet_cidr
  
  tags = {
    Name = "singapore-subnet"
  }
}
resource "aws_subnet" "singapore" {
  vpc_id     = aws_vpc.main-sg.id
  cidr_block = var.sg_subnet_cidr
  provider   = aws.singapore

  tags = {
    Name = "singapore-subnet"
  }
}

# Create Ireland subnet
resource "aws_subnet" "ireland" {
  provider   = aws.ireland
  vpc_id     = aws_vpc.main-ie.id
  cidr_block = var.ie_subnet_cidr
  availability_zone = "eu-west-1a"

  tags = {
    Name = "ireland-subnet"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}
resource "aws_internet_gateway" "main-sg" {
  vpc_id = aws_vpc.main-sg.id

  tags = {
    Name = "main-sg-igw"
  }
}
resource "aws_internet_gateway" "main-ie" {
  vpc_id = aws_vpc.main-ie.id

  tags = {
    Name = "main-ie-igw"
  }
}

# Create Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "main-route-table"
  }
}
resource "aws_route_table" "main-sg" {
  vpc_id = aws_vpc.main-sg.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-sg.id
  }

  tags = {
    Name = "main-sg-route-table"
  }
}
resource "aws_route_table" "main-ie" {
  vpc_id = aws_vpc.main-ie.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-ie.id
  }

  tags = {
    Name = "main-ie-route-table"
  }
}

# Associate Route Table with Subnets
resource "aws_route_table_association" "singapore" {
  subnet_id      = aws_subnet.singapore.id
  route_table_id = aws_route_table.main-sg.id
}

resource "aws_route_table_association" "ireland" {
  provider       = aws.ireland
  subnet_id      = aws_subnet.ireland.id
  route_table_id = aws_route_table.main-sg.id
}

# Create Security Group
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from VPC"
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
    Name = "allow_ssh"
  }
}
resource "aws_security_group" "allow_ssh-sg" {
  name        = "allow_ssh-sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main-sg.id

  ingress {
    description = "SSH from VPC"
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
    Name = "allow_ssh-sg"
  }
}
resource "aws_security_group" "allow_ssh-ie" {
  name        = "allow_ssh-ie"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main-ie.id

  ingress {
    description = "SSH from VPC"
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
    Name = "allow_ssh-ie"
  }
}
# Create EC2 instance in Singapore
resource "aws_instance" "singapore" {
  ami           = "ami-005fc0f236362e99f"  
  instance_type = var.instance_type
  subnet_id     = aws_subnet.singapore.id
  vpc_security_group_ids = [aws_security_group.allow_ssh-sg.id]
  key_name      = "damian"

  tags = {
    Name = "singapore-instance"
  }
}

# Create EC2 instance in Ireland
resource "aws_instance" "ireland" {
  provider      = aws.ireland
  ami           = "ami-005fc0f236362e99f"  
  instance_type = var.instance_type
  subnet_id     = aws_subnet.ireland.id
  vpc_security_group_ids = [aws_security_group.allow_ssh-ie.id]
  key_name      = "damian"

  tags = {
    Name = "ireland-instance"
  }
}

# Create RDS MySQL instance in Singapore
resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.singapore.id, aws_subnet.ireland.id]

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = var.db_instance_class
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.allow_ssh-sg.id]
  skip_final_snapshot  = true

  tags = {
    Name = "singapore-mysql-instance"
  }
}

# Create Application Load Balancer
resource "aws_lb" "main" {
  name               = "main-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.singapore.id, aws_subnet.ireland.id]

  enable_deletion_protection = false

  tags = {
    Name = "main-alb"
  }
}

# ALB Listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Access Denied"
      status_code  = "403"
    }
  }
}

# ALB Target Groups
resource "aws_lb_target_group" "singapore" {
  name     = "tg-singapore"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main-sg.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

resource "aws_lb_target_group" "ireland" {
  provider = aws.ireland
  name     = "tg-ireland"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main-ie.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

# Weighted target groups for traffic distribution
resource "aws_lb_listener_rule" "weighted" {
  listener_arn = aws_lb_listener.front_end.arn
  priority     = 50

  action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.singapore.arn
        weight = 60
      }
      target_group {
        arn    = aws_lb_target_group.ireland.arn
        weight = 30
      }
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

# Geographical restriction
resource "aws_wafv2_web_acl" "main" {
  name        = "geo-restriction"
  description = "Geo restriction for France"
  scope       = "REGIONAL"

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
      metric_name                = "BlockFrance"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "GeoRestriction"
    sampled_requests_enabled   = true
  }
}

# Associate WAF with ALB
resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = aws_lb.main.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}


