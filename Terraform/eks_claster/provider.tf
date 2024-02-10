provider "aws" {
  region = "us-east-1"
}


provider "kubernetes" {
  config_context_cluster = "my-cluster"
}
