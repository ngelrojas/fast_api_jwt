terraform {
  backend "s3" {
    bucket         = "tf-state-locks-fast-api-jwt"
    key            = "terraform/state/production.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-table-locks-fast-api-jwt"
    encrypt        = true
  }
}
