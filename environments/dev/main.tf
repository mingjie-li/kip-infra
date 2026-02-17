terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "network" {
  source = "../../modules/network"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment
}

module "gke" {
  source = "../../modules/gke"

  project_id     = var.project_id
  region         = var.region
  environment    = var.environment
  network_id     = module.network.network_id
  subnet_id      = module.network.subnet_id
  machine_type   = var.machine_type
  min_node_count = var.min_node_count
  max_node_count = var.max_node_count
  spot_vms       = true
}

module "artifact_registry" {
  source = "../../modules/artifact-registry"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment
}

module "dns" {
  source = "../../modules/dns"

  project_id  = var.project_id
  environment = var.environment
  domain      = "dev.kube-intel.com"
}

module "cdn" {
  source = "../../modules/cdn"

  project_id         = var.project_id
  storage_project_id = var.storage_project_id
  environment        = var.environment
  domain             = "dev.kube-intel.com"
  zone_name          = module.dns.zone_name
}
