
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
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "dam-sg-subnet-pub"
  }
}
resource "aws_subnet" "dam-sg-pusubnet1" {
  provider   = aws.singapore
  vpc_id     = aws_vpc.dam-sg-vpc.id
  cidr_block = var.sg_pusubnet_cidr2
  availability_zone = "ap-southeast-1b"

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
resource "aws_subnet" "dam-ie-pusubnet1" {
  provider   = aws.ireland
  vpc_id     = aws_vpc.dam-ie-vpc.id
  cidr_block = var.ie_pusubnet_cidr2

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
resource "aws_route_table_association" "dam-sg-rta1" {
  provider       = aws.singapore
  subnet_id      = aws_subnet.dam-sg-pusubnet1.id
  route_table_id = aws_route_table.dam-sg-rt.id
}
resource "aws_route_table_association" "dam-ie-rta" {
  provider       = aws.ireland
  subnet_id      = aws_subnet.dam-ie-pusubnet.id
  route_table_id = aws_route_table.dam-ie-rt.id
}
resource "aws_route_table_association" "dam-ie-rta1" {
  provider       = aws.ireland
  subnet_id      = aws_subnet.dam-ie-pusubnet1.id
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



# Auto Scaling configuration for peak users
resource "aws_autoscaling_group" "dam-sg-asg" {
  name                = "dam-sg-asg"
  vpc_zone_identifier = [aws_subnet.dam-sg-pusubnet.id]
  target_group_arns   = [aws_lb_target_group.dam-sg-tg.arn]
  min_size            = 1
  max_size            = 10
  desired_capacity    = 1
  provider            = aws.singapore

  launch_template {
    id      = aws_launch_template.ec2-template-sg.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_group" "dam-ie-asg" {
  name                = "dam-ie-asg"
  vpc_zone_identifier = [aws_subnet.dam-ie-pusubnet.id]
  target_group_arns   = [aws_lb_target_group.dam-ie-tg.arn]
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
  key_name      = "damian-sg"
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
  key_name      = "damian-ie"
  provider      = aws.ireland
  

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.dam-ie-sg.id]
  }
}

resource "aws_autoscaling_policy" "damian-sg-policy" {
  name                   = "damian-sg-policy"
  policy_type            = "TargetTrackingScaling"
  provider               = aws.singapore
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
  provider            = aws.ireland
  autoscaling_group_name = aws_autoscaling_group.dam-ie-asg.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}
# VPC Peering connection
resource "aws_vpc_peering_connection" "singapore-ireland" {
  provider    = aws.singapore
  vpc_id      = aws_vpc.dam-sg-vpc.id
  peer_vpc_id = aws_vpc.dam-ie-vpc.id
  peer_region = "eu-west-1"
  auto_accept = false

  tags = {
    Name = "singapore-ireland-peering"
  }
}

# Accept VPC peering connection in Ireland
resource "aws_vpc_peering_connection_accepter" "ireland-accepter" {
  provider                  = aws.ireland
  vpc_peering_connection_id = aws_vpc_peering_connection.singapore-ireland.id
  auto_accept              = true

  tags = {
    Name = "ireland-accepter"
  }
}
# Route 53 Private Hosted Zone
resource "aws_route53_zone" "ie-private" {
  provider = aws.singapore
  name     = "damian.internal"

  vpc {
    vpc_id = aws_vpc.dam-sg-vpc.id
  }
}


resource "aws_route53_record" "dam-sg-rou53-1" {
  provider = aws.singapore
  
  zone_id = aws_route53_zone.ie-private.zone_id
  name    = "app"  # This will create app.internal.service
  type    = "A"
  ttl     = "300"

  weighted_routing_policy {
    weight = 60
  }
  set_identifier = "singapore"
  records       = ["10.0.3.121", "10.0.1.65"]  # Replace with your Singapore server IP
}
resource "aws_route53_record" "dam-ie-rou53-1" {
  provider = aws.ireland
  
  zone_id = aws_route53_zone.ie-private.zone_id
  name    = "app"
  type    = "A"
  ttl     = "300"
  

  weighted_routing_policy {
    weight = 30
  }
  set_identifier = "ireland"
  records       = ["172.0.3.193", "172.0.1.203"]  # Replace with your Ireland server IP
}

resource "aws_route53_vpc_association_authorization" "ireland_auth" {
  provider = aws.ireland  # Authorization must be from the hosted zone's region
  vpc_id   = aws_vpc.dam-ie-vpc.id
  zone_id  = aws_route53_zone.ie-private.id
}
#  Create the association from Ireland
resource "aws_route53_zone_association" "ireland_assoc" {
  provider = aws.ireland   # Association must be from the VPC's region
  vpc_id   = aws_vpc.dam-ie-vpc.id
  zone_id  = aws_route53_zone.ie-private.id

  depends_on = [aws_route53_vpc_association_authorization.ireland_auth]
}
# Create WAF Web ACL
resource "aws_wafv2_web_acl" "geo_block_fr_sg" {
  name        = "geo-block-france-sg"
  description = "Block traffic from France"
  scope       = "REGIONAL"  
  provider    = aws.singapore

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
      metric_name               = "BlockFranceMetric"
      sampled_requests_enabled  = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "GeoblockWAFMetric"
    sampled_requests_enabled  = true
  }
}
resource "aws_wafv2_web_acl_association" "alb_association_sg" {
  provider     = aws.singapore
  resource_arn = aws_lb.dam-sg-alb.arn  # Replace with your ALB ARN
  web_acl_arn  = aws_wafv2_web_acl.geo_block_fr_sg.arn
}

resource "aws_wafv2_web_acl" "geo_block_fr_ie" {
  name        = "geo-block-france-ie"
  description = "Block traffic from France"
  scope       = "REGIONAL"  
  provider    = aws.ireland

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
      metric_name               = "BlockFranceMetric"
      sampled_requests_enabled  = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "GeoblockWAFMetric"
    sampled_requests_enabled  = true
  }
}
resource "aws_wafv2_web_acl_association" "alb_association_ie" {
  provider     = aws.ireland
  resource_arn = aws_lb.dam-ie-alb.arn  # Replace with your ALB ARN
  web_acl_arn  = aws_wafv2_web_acl.geo_block_fr_ie.arn
}
# Security Group for the ALB
resource "aws_security_group" "dam-sg-sgalb" {
  name        = "dam-sg-sgalb"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.dam-sg-vpc.id
  provider        = aws.singapore

  ingress {
    description = "HTTP from anywhere"
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
}
# Application Load Balancer
resource "aws_lb" "dam-sg-alb" {
  name               = "dam-sg-alb"
  provider           = aws.singapore
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.dam-sg-sgalb.id]
  subnets            = [aws_subnet.dam-sg-pusubnet.id, aws_subnet.dam-sg-pusubnet1.id]
  enable_deletion_protection = true

}

# Target Group
resource "aws_lb_target_group" "dam-sg-tg" {
  name     = "dam-sg-tg"
  provider = aws.singapore
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.dam-sg-vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher            = "200"
    path               = "/"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 5
    unhealthy_threshold = 2
  }
}
# Listener
resource "aws_lb_listener" "dam-sg-listen" {
  load_balancer_arn = aws_lb.dam-sg-alb.arn
  port              = 80
  protocol          = "HTTP"
  provider        = aws.singapore

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dam-sg-tg.arn
  }
}

# Security Group for the ALB
resource "aws_security_group" "dam-ie-sgalb" {
  name        = "dam-ie-sgalb"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.dam-ie-vpc.id
  provider        = aws.ireland

  ingress {
    description = "HTTP from anywhere"
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
}
# Application Load Balancer
resource "aws_lb" "dam-ie-alb" {
  name               = "dam-ie-alb"
  provider           = aws.ireland
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.dam-ie-sgalb.id]
  subnets            = [aws_subnet.dam-ie-pusubnet.id, aws_subnet.dam-ie-pusubnet1.id]
  enable_deletion_protection = true

}

# Target Group
resource "aws_lb_target_group" "dam-ie-tg" {
  name     = "dam-ie-tg"
  provider = aws.ireland
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.dam-ie-vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher            = "200"
    path               = "/"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 5
    unhealthy_threshold = 2
  }
}
# Listener
resource "aws_lb_listener" "dam-ie-listen" {
  load_balancer_arn = aws_lb.dam-ie-alb.arn
  port              = 80
  protocol          = "HTTP"
  provider        = aws.ireland

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dam-ie-tg.arn
  }
}

/*
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
