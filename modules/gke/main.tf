resource "google_service_account" "nodes" {
  account_id   = "kip-${var.environment}-gke-nodes"
  display_name = "GKE Node Pool SA (${var.environment})"
  project      = var.project_id
}

resource "google_project_iam_member" "nodes_ar_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.nodes.email}"
}

resource "google_container_cluster" "cluster" {
  name     = "kip-${var.environment}-cluster"
  project  = var.project_id
  location = var.region

  network    = var.network_id
  subnetwork = var.subnet_id

  # Use a separately managed node pool
  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel {
    channel = var.release_channel
  }

  node_config {
    disk_size_gb = var.disk_size_gb
    spot         = var.spot_vms
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  network_policy {
    enabled = true
  }

  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }

  monitoring_config {
    managed_prometheus {
      enabled = false
    }
    enable_components = []
  }

  deletion_protection = false
}

resource "google_compute_global_address" "gateway" {
  count   = var.enable_gateway_api ? 1 : 0
  name    = "kip-${var.environment}-gateway-ip"
  project = var.project_id
}

locals {
  create_gateway_cert = var.enable_gateway_api && var.gateway_domain != ""
}

resource "google_project_service" "certificate_manager" {
  count   = local.create_gateway_cert ? 1 : 0
  project = var.project_id
  service = "certificatemanager.googleapis.com"

  disable_on_destroy = false
}

resource "google_certificate_manager_dns_authorization" "gateway" {
  depends_on = [google_project_service.certificate_manager]
  count   = local.create_gateway_cert ? 1 : 0
  name    = "kip-${var.environment}-gateway-dns-auth"
  project = var.project_id
  domain  = var.gateway_domain
}

resource "google_dns_record_set" "gateway_dns_auth" {
  count        = local.create_gateway_cert ? 1 : 0
  name         = google_certificate_manager_dns_authorization.gateway[0].dns_resource_record[0].name
  project      = var.gateway_dns_project_id != "" ? var.gateway_dns_project_id : var.project_id
  type         = google_certificate_manager_dns_authorization.gateway[0].dns_resource_record[0].type
  ttl          = 300
  managed_zone = var.gateway_dns_zone
  rrdatas      = [google_certificate_manager_dns_authorization.gateway[0].dns_resource_record[0].data]
}

resource "google_dns_record_set" "gateway_wildcard" {
  count        = var.enable_gateway_api ? 1 : 0
  name         = "*.${var.gateway_domain}."
  project      = var.gateway_dns_project_id != "" ? var.gateway_dns_project_id : var.project_id
  type         = "A"
  ttl          = 300
  managed_zone = var.gateway_dns_zone
  rrdatas      = [google_compute_global_address.gateway[0].address]
}

resource "google_certificate_manager_certificate" "gateway" {
  count   = local.create_gateway_cert ? 1 : 0
  name    = "kip-${var.environment}-gateway-cert"
  project = var.project_id
  scope   = "DEFAULT" # certificate maps require DEFAULT scope

  managed {
    domains            = ["*.${var.gateway_domain}"]
    dns_authorizations = [google_certificate_manager_dns_authorization.gateway[0].id]
  }
}

resource "google_certificate_manager_certificate_map" "gateway" {
  count   = local.create_gateway_cert ? 1 : 0
  name    = "kip-${var.environment}-gateway-certmap"
  project = var.project_id
}

resource "google_certificate_manager_certificate_map_entry" "gateway" {
  count        = local.create_gateway_cert ? 1 : 0
  name         = "kip-${var.environment}-gateway-certmap-entry"
  project      = var.project_id
  map          = google_certificate_manager_certificate_map.gateway[0].name
  certificates = [google_certificate_manager_certificate.gateway[0].id]
  hostname     = "*.${var.gateway_domain}"
}

resource "google_container_node_pool" "default" {
  name     = "kip-${var.environment}-default-pool"
  project  = var.project_id
  location = var.region
  cluster  = google_container_cluster.cluster.name

  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  node_config {
    machine_type    = var.machine_type
    disk_size_gb    = var.disk_size_gb
    service_account = google_service_account.nodes.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    spot = var.spot_vms

    shielded_instance_config {
      enable_secure_boot = true
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
