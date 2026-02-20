# Pub/Sub topic for GKE audit logs
resource "google_pubsub_topic" "gke_audit_logs" {
  name    = "gke-audit-logs"
  project = var.project_id

  message_retention_duration = "86400s" # 1 day
}

# Pub/Sub subscription for the otel-collector to pull from
resource "google_pubsub_subscription" "gke_audit_logs_otel" {
  name    = "gke-audit-logs-otel"
  topic   = google_pubsub_topic.gke_audit_logs.name
  project = var.project_id

  # Acknowledge deadline - how long the subscriber has to ack before redelivery
  ack_deadline_seconds = 60

  # Retain unacked messages for 1 day
  message_retention_duration = "86400s"

  # Retain acked messages for 1 hour (for debugging)
  retain_acked_messages = true

  expiration_policy {
    ttl = "" # Never expire
  }
}

# Log sink to export GKE audit logs to Pub/Sub
resource "google_logging_project_sink" "gke_audit_sink" {
  name        = "gke-audit-logs-sink"
  project     = var.project_id
  destination = "pubsub.googleapis.com/${google_pubsub_topic.gke_audit_logs.id}"

  # Filter for GKE/K8s audit logs from this cluster
  filter = <<-EOT
    resource.type="k8s_cluster"
    logName=~"projects/${var.project_id}/logs/cloudaudit.googleapis.com%2F(activity|data_access)"
  EOT

  # Use a unique writer identity for this sink
  unique_writer_identity = true
}

# Grant the log sink's service account permission to publish to the Pub/Sub topic
resource "google_pubsub_topic_iam_member" "sink_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.gke_audit_logs.name
  role    = "roles/pubsub.publisher"
  member  = google_logging_project_sink.gke_audit_sink.writer_identity
}

# Service account for the otel-collector to access Pub/Sub
resource "google_service_account" "otel_collector" {
  account_id   = "otel-collector-sa"
  display_name = "OpenTelemetry Collector Service Account"
  project      = var.project_id
}

# Grant the otel-collector service account permission to subscribe
resource "google_pubsub_subscription_iam_member" "otel_subscriber" {
  project      = var.project_id
  subscription = google_pubsub_subscription.gke_audit_logs_otel.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.otel_collector.email}"
}

# Also grant viewer role on the subscription
resource "google_pubsub_subscription_iam_member" "otel_viewer" {
  project      = var.project_id
  subscription = google_pubsub_subscription.gke_audit_logs_otel.name
  role         = "roles/pubsub.viewer"
  member       = "serviceAccount:${google_service_account.otel_collector.email}"
}

# Workload Identity binding - allows K8s SA to act as GCP SA
resource "google_service_account_iam_member" "otel_workload_identity" {
  service_account_id = google_service_account.otel_collector.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[opentelemetry-operator-system/kip-collector-daemonset-collector]"
}


# Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "apikeys.googleapis.com",
    "cloudbilling.googleapis.com",
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}


# billing api key
resource "google_apikeys_key" "billing" {
  name         = "billing-api-key"
  display_name = "API key for accessing Google Cloud Billing API"
  project = var.project_id
  depends_on = [ google_project_service.apis ]
  restrictions {
        api_targets {
            service = "cloudbilling.googleapis.com"
        }
  }
}
