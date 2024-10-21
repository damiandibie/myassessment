terraform {
  backend "s3" {
    bucket = "damiand-assess-bucket"
    dynamodb_table = "damiand-lock-state"
    key    = "damian/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    acl = "bucket-owner-full-control"
  }
}
