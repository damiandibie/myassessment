terraform {
  backend "s3" {
    bucket = "damian-assess-bucket"
    dynamodb_table = "damian-lock-state"
    key    = "damian/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    acl = "bucket-owner-full-control"
  }
}
