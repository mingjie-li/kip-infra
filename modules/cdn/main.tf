resource "google_storage_bucket" "static" {
  name                        = "kip-${var.environment}-static"
  project                     = var.storage_project_id
  location                    = "US-EAST1"
  uniform_bucket_level_access = true
  public_access_prevention    = "inherited"
}

resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.static.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
  depends_on = [ 
    google_project_organization_policy.disable_domain_restricted_sharing,
    google_project_organization_policy.disable_pap,
  ]
}

resource "google_compute_global_address" "lb_ip" {
  name    = "kip-${var.environment}-lb-ip"
  project = var.project_id
}

resource "google_compute_backend_bucket" "cdn" {
  name        = "kip-${var.environment}-backend"
  project     = var.project_id
  bucket_name = google_storage_bucket.static.name
  enable_cdn  = true
}

resource "google_compute_url_map" "https" {
  name            = "kip-${var.environment}-url-map"
  project         = var.project_id
  default_service = google_compute_backend_bucket.cdn.self_link
}

resource "google_compute_managed_ssl_certificate" "cert" {
  name    = "kip-${var.environment}-cert"
  project = var.project_id

  managed {
    domains = ["${var.domain}."]
  }
}

resource "google_compute_target_https_proxy" "https" {
  name             = "kip-${var.environment}-https-proxy"
  project          = var.project_id
  url_map          = google_compute_url_map.https.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.cert.self_link]
}

resource "google_compute_global_forwarding_rule" "https" {
  name       = "kip-${var.environment}-https-fwd"
  project    = var.project_id
  target     = google_compute_target_https_proxy.https.self_link
  ip_address = google_compute_global_address.lb_ip.address
  port_range = "443"
}

resource "google_compute_url_map" "http_redirect" {
  name    = "kip-${var.environment}-http-redirect"
  project = var.project_id

  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }
}

resource "google_compute_target_http_proxy" "http" {
  name    = "kip-${var.environment}-http-proxy"
  project = var.project_id
  url_map = google_compute_url_map.http_redirect.self_link
}

resource "google_compute_global_forwarding_rule" "http" {
  name       = "kip-${var.environment}-http-fwd"
  project    = var.project_id
  target     = google_compute_target_http_proxy.http.self_link
  ip_address = google_compute_global_address.lb_ip.address
  port_range = "80"
}

resource "google_dns_record_set" "root" {
  name         = "${var.domain}."
  project      = var.project_id
  type         = "A"
  ttl          = 300
  managed_zone = var.zone_name
  rrdatas      = [google_compute_global_address.lb_ip.address]
}
resource "google_project_organization_policy" "disable_domain_restricted_sharing" {
  project    = var.storage_project_id
  constraint = "constraints/iam.allowedPolicyMemberDomains"

  restore_policy {
    default = true
  }
}

resource "google_project_organization_policy" "disable_pap" {
  project    = var.storage_project_id
  constraint = "constraints/storage.publicAccessPrevention"

  boolean_policy {
    enforced = false
  }
}