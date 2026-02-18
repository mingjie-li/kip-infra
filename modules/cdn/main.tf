resource "google_storage_bucket" "static" {
  name                        = "kip-${var.environment}-static"
  project                     = var.storage_project_id
  location                    = "US-EAST1"
  uniform_bucket_level_access = true
  public_access_prevention    = "inherited"

  website {
    main_page_suffix = "index.html"
  }
}

resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.static.name
  role   = "roles/storage.legacyObjectReader"
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

resource "google_project_service" "certificate_manager" {
  project            = var.project_id
  service            = "certificatemanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_certificate_manager_dns_authorization" "cdn" {
  depends_on = [google_project_service.certificate_manager]
  name       = "kip-${var.environment}-cdn-dns-auth"
  project    = var.project_id
  domain     = var.domain
}

resource "google_dns_record_set" "cdn_dns_auth" {
  name         = google_certificate_manager_dns_authorization.cdn.dns_resource_record[0].name
  project      = var.project_id
  type         = google_certificate_manager_dns_authorization.cdn.dns_resource_record[0].type
  ttl          = 300
  managed_zone = var.zone_name
  rrdatas      = [google_certificate_manager_dns_authorization.cdn.dns_resource_record[0].data]
}

resource "google_certificate_manager_certificate" "cdn" {
  name    = "kip-${var.environment}-cdn-cert"
  project = var.project_id
  scope   = "DEFAULT"

  managed {
    domains            = ["*.${var.domain}"]
    dns_authorizations = [google_certificate_manager_dns_authorization.cdn.id]
  }
}

resource "google_certificate_manager_certificate_map" "cdn" {
  name    = "kip-${var.environment}-cdn-certmap"
  project = var.project_id
}

resource "google_certificate_manager_certificate_map_entry" "cdn" {
  name         = "kip-${var.environment}-cdn-certmap-entry"
  project      = var.project_id
  map          = google_certificate_manager_certificate_map.cdn.name
  certificates = [google_certificate_manager_certificate.cdn.id]
  hostname     = "*.${var.domain}"
}

resource "google_compute_target_https_proxy" "https" {
  name             = "kip-${var.environment}-https-proxy"
  project          = var.project_id
  url_map          = google_compute_url_map.https.self_link
  certificate_map  = "//certificatemanager.googleapis.com/${google_certificate_manager_certificate_map.cdn.id}"
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

resource "google_dns_record_set" "wildcard" {
  name         = "*.${var.domain}."
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