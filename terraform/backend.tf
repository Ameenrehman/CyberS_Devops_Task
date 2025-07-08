terraform {
  backend "s3" {
    bucket = "my-terraform-state-bucket-ameen1"
    key    = "tfstate/main1.tfstate"
    region = "us-east-1"
  }
}
