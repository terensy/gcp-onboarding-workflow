output "analytics_bucket_id" {
  description = "Log Analytics Bucket 的 bucket_id（未啟用則為 null）。"
  value       = var.enable_analytics_sink ? google_logging_project_bucket_config.analytics[0].bucket_id : null
}

output "storage_archive_bucket_name" {
  description = "長期保存用 Cloud Storage Bucket 名稱（未啟用則為 null）。"
  value       = var.enable_storage_archive_sink ? google_storage_bucket.archive[0].name : null
}

output "pubsub_siem_topic_id" {
  description = "轉送 SIEM 用的 Pub/Sub Topic 完整 ID（未設定則為 null）。"
  value       = var.pubsub_siem_topic_name != "" ? google_pubsub_topic.siem[0].id : null
}

output "audit_config_services" {
  description = "已設定 Data Access Audit Log 的服務清單，方便核對範圍。"
  value       = keys(var.audit_configs)
}
