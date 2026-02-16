terraform {
  backend "gcs" {
    bucket = "YOUR_PROJECT_ID-tfstate-staging"
    prefix = "terraform/state"
  }
}
