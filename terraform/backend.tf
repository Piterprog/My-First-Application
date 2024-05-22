

terraform {
  backend "s3" {
    bucket     = "staging-terraform-state-piter"
    key        = "terraform/terraform.tfstate"
    region     = "us-east-1"
    encrypt    = true
  }
}



