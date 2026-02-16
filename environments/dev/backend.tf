terraform {
  backend "gcs" {
    bucket = "kip-dev-tfstate-dev"
    prefix = "terraform/state"
  }
}
