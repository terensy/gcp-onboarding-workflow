module "aggregated_logging" {
  source = "../../modules/aggregated_logging"

  org_id             = var.org_id
  logging_project_id = var.logging_project_id
  audit_configs      = var.audit_configs
}

output "analytics_bucket_id" {
  value = module.aggregated_logging.analytics_bucket_id
}

output "storage_archive_bucket_name" {
  value = module.aggregated_logging.storage_archive_bucket_name
}

output "audit_config_services" {
  value = module.aggregated_logging.audit_config_services
}
