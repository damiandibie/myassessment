variable "damiand-s3" {
  default = "damiand-assess-bucket"
}
variable "db_username" {

}
variable "db_password" {

}

variable "vpc_cidr_sg" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "sg_pusubnet_cidr" {
  description = "CIDR block for the subnet in Singapore"
  default     = "10.0.1.0/24"
}
variable "sg_pusubnet_cidr2" {
  description = "CIDR block for the subnet in Singapore"
  default     = "10.0.3.0/24"
}
variable "sg_prsubnet_cidr" {
  description = "CIDR block for the subnet in Singapore"
  default     = "10.0.2.0/24"
}
variable "vpc_cidr_ie" {
  description = "CIDR block for the VPC"
  default     = "172.0.0.0/16"
}
variable "ie_pusubnet_cidr" {
  description = "CIDR block for the subnet in Singapore"
  default     = "172.0.1.0/24"
}
variable "ie_pusubnet_cidr2" {
  description = "CIDR block for the subnet in Singapore"
  default     = "172.0.3.0/24"
}
variable "ie_prsubnet_cidr" {
  description = "CIDR block for the subnet in Singapore"
  default     = "172.0.2.0/24"
}
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}
variable "dam-sg-ec2" {
  default     = "dam-sg-ec2"
}
variable "dam-ie-ec2" {
  default     = "dam-ie-ec2"
}
variable "dam-sg-lb" {
  default     = "dam-sg-lb"
}
variable "dam-sg-alb-sg" {
  default     = "dam-sg-alb-sg"
}
variable "dam-ie-asg" {
  default     = "dam-ie-asg"
}
variable "ec2-template-ie" {
  default     = "ec2-template-ie"
}
variable "dam-sg-pusubnet_1" {
  default     = "ap_southeast_1a"
}
variable "dam-sg-pusubnet_2" {
  default     = "ap_southeast_1b"
}
