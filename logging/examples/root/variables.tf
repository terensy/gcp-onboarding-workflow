variable "org_id" {
  type        = string
  description = "GCP Organization ID。"
}

variable "logging_project_id" {
  type        = string
  description = "集中收 log 的 Project ID，詳見 modules/aggregated_logging/variables.tf。"
}

variable "audit_configs" {
  type        = map(list(string))
  description = "Data Access Audit Log 設定，詳見 modules/aggregated_logging/variables.tf。"
  default     = {}
}
