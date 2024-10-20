variable "damian-s3" {
   default = "damian-assess-bucket"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "aws_region" {
  description = "The AWS region to create resources in"
  default     = "ap-southeast-1"  # Singapore
}

variable "sg_subnet_cidr" {
  description = "CIDR block for the subnet in Singapore"
  default     = "10.0.1.0/24"
}

variable "ie_subnet_cidr" {
  description = "CIDR block for the subnet in Ireland"
  default     = "10.0.2.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "db_instance_class" {
  description = "RDS instance class"
  default     = "db.t2.micro"
}

variable "db_name" {
  description = "Name of the database"
  default     = "mydb"
}

variable "db_username" {
  description = "Username for the database"
}

variable "db_password" {
  description = "Password for the database"
}

variable "aws_security_group" {
   default = "allow_ssh"

}