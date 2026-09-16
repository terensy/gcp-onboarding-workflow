# ---------------------------------------------------------------------------
# Log Analytics Bucket——即時查詢、事故發生當下的 Ad Hoc 調查
# ---------------------------------------------------------------------------
resource "google_logging_project_bucket_config" "analytics" {
  count = var.enable_analytics_sink ? 1 : 0

  project          = var.logging_project_id
  location         = var.logging_bucket_location
  bucket_id        = "log-analytics"
  retention_days   = var.analytics_retention_days
  enable_analytics = true
}

resource "google_logging_organization_sink" "analytics" {
  count = var.enable_analytics_sink ? 1 : 0

  name             = "sk-org-logging-analytics"
  org_id           = var.org_id
  include_children = true
  filter           = var.analytics_sink_filter

  destination = "logging.googleapis.com/projects/${var.logging_project_id}/locations/${var.logging_bucket_location}/buckets/${google_logging_project_bucket_config.analytics[0].bucket_id}"
}

resource "google_project_iam_member" "analytics_sink_writer" {
  count = var.enable_analytics_sink ? 1 : 0

  project = var.logging_project_id
  role    = "roles/logging.bucketWriter"
  member  = google_logging_organization_sink.analytics[0].writer_identity
}

# ---------------------------------------------------------------------------
# Cloud Storage Bucket——長期保存，符合法遵/稽核需求
# ---------------------------------------------------------------------------
resource "google_storage_bucket" "archive" {
  count = var.enable_storage_archive_sink ? 1 : 0

  project                     = var.logging_project_id
  name                        = "${var.logging_project_id}-log-archive"
  location                    = var.logging_bucket_location
  uniform_bucket_level_access = true
  force_destroy               = false

  lifecycle_rule {
    condition {
      age = var.storage_archive_retention_days
    }
    action {
      type = "Delete"
    }
  }

  # Bucket Lock：見 variable 說明，預設關閉，確認保留天數設對之後再手動開啟。
  # 開啟後這個設定本身也會變成不可逆，所以刻意不讓 retention_policy 在
  # lock_storage_archive_bucket = false 時就先建立，避免踩到「先建立了
  # retention_policy、之後才想改天數」的坑。
  dynamic "retention_policy" {
    for_each = var.lock_storage_archive_bucket ? [1] : []
    content {
      is_locked        = true
      retention_period = var.storage_archive_retention_days * 24 * 60 * 60
    }
  }
}

resource "google_logging_organization_sink" "storage_archive" {
  count = var.enable_storage_archive_sink ? 1 : 0

  name             = "sk-org-logging-storage-archive"
  org_id           = var.org_id
  include_children = true
  filter           = var.storage_archive_sink_filter

  destination = "storage.googleapis.com/${google_storage_bucket.archive[0].name}"
}

resource "google_storage_bucket_iam_member" "storage_archive_sink_writer" {
  count = var.enable_storage_archive_sink ? 1 : 0

  bucket = google_storage_bucket.archive[0].name
  role   = "roles/storage.objectCreator"
  member = google_logging_organization_sink.storage_archive[0].writer_identity
}

# ---------------------------------------------------------------------------
# Pub/Sub——轉送到外部 SIEM（選填）
# ---------------------------------------------------------------------------
resource "google_pubsub_topic" "siem" {
  count = var.pubsub_siem_topic_name != "" ? 1 : 0

  project = var.logging_project_id
  name    = var.pubsub_siem_topic_name
}

resource "google_logging_organization_sink" "siem" {
  count = var.pubsub_siem_topic_name != "" ? 1 : 0

  name             = "sk-org-logging-siem"
  org_id           = var.org_id
  include_children = true

  destination = "pubsub.googleapis.com/${google_pubsub_topic.siem[0].id}"
}

resource "google_pubsub_topic_iam_member" "siem_sink_writer" {
  count = var.pubsub_siem_topic_name != "" ? 1 : 0

  project = var.logging_project_id
  topic   = google_pubsub_topic.siem[0].name
  role    = "roles/pubsub.publisher"
  member  = google_logging_organization_sink.siem[0].writer_identity
}

# ---------------------------------------------------------------------------
# Data Access Audit Log（IAM auditConfigs，不是 Organization Policy）
# ---------------------------------------------------------------------------
resource "google_organization_iam_audit_config" "this" {
  for_each = var.audit_configs

  org_id  = var.org_id
  service = each.key

  dynamic "audit_log_config" {
    for_each = each.value
    content {
      log_type = audit_log_config.value
    }
  }
}
