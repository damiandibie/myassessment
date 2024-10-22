variable "damiand-s3" {
   default = "damiand-assess-bucket"
}
variable "db_username" {
   
}
variable "db_password" {
   
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "sg_subnet_cidr" {
  description = "CIDR block for the subnet in Singapore"
  default     = "10.0.1.0/24"
}

variable "ie_subnet_cidr" {
  description = "CIDR block for the subnet in Singapore"
  default     = "10.0.1.0/24"
}
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}
