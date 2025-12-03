terraform {
  backend "s3" {
    bucket         = "eks-2048-game"
    key            = "infra"
    region         = "eu-west-2"
    dynamodb_table = "eks-locks"
    encrypt        = true
  }
}
