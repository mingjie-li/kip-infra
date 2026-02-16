terraform {
  backend "gcs" {
    bucket = "kip-dev-487617-t9-tfstate-dev"
    prefix = "terraform/state"
  }
}
