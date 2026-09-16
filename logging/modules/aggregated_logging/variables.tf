variable "org_id" {
  type        = string
  description = "GCP Organization ID，Aggregated Sink 與 Data Access Audit Config 都掛在這裡。"
}

variable "logging_project_id" {
  type        = string
  description = <<-EOT
    集中收 log 的獨立 Project ID（對應最外層 README.md 4.2 節「集中式 Log
    Sink」）。這個 Project 假設已經存在（透過 2.1 節的 Folder/Project 規劃建立），
    這個 module 不負責建立 Project 本身，只負責在裡面建 Log Bucket 並把
    Organization 的 log 匯過來。管理這個 Project 的人應該跟一般 Workload
    Project 的管理員分開，見 iam-bindings/ 的 gcp-logging-admins@ 綁定。
  EOT
}

variable "logging_bucket_location" {
  type        = string
  description = "Log Analytics Bucket 與 Storage Bucket 所在地區。"
  default     = "asia-east1"
}

variable "enable_analytics_sink" {
  type        = bool
  description = "是否建立 Log Analytics Bucket（掛 BigQuery，供即時查詢/Ad Hoc 調查）。"
  default     = true
}

variable "analytics_retention_days" {
  type        = number
  description = "Log Analytics Bucket 的保留天數（1~3650）。"
  default     = 30
}

variable "analytics_sink_filter" {
  type        = string
  description = "Analytics Sink 的 log filter，預設收 Admin Activity / System Event / Policy Denied 等稽核紀錄。"
  default     = <<-EOT
    logName:"/logs/cloudaudit.googleapis.com%2Factivity" OR
    logName:"/logs/cloudaudit.googleapis.com%2Fsystem_event" OR
    logName:"/logs/cloudaudit.googleapis.com%2Fpolicy"
  EOT
}

variable "enable_storage_archive_sink" {
  type        = bool
  description = "是否建立 Cloud Storage Bucket 做長期保存（符合法遵/稽核需求）。"
  default     = true
}

variable "storage_archive_retention_days" {
  type        = number
  description = "Cloud Storage 長期保存 Bucket 的物件生命週期天數。"
  default     = 400
}

variable "lock_storage_archive_bucket" {
  type        = bool
  description = <<-EOT
    是否對長期保存用的 Cloud Storage Bucket 開啟 Bucket Lock（保留政策鎖定，
    不可逆——鎖定之後保留天數不能再改短也不能改長，見最外層 README.md 4.3
    節）。預設關閉，確認保留天數設對之後再手動改成 true。
  EOT
  default     = false
}

variable "storage_archive_sink_filter" {
  type        = string
  description = "Storage Archive Sink 的 log filter，預設收所有 log（不分服務）。"
  default     = ""
}

variable "pubsub_siem_topic_name" {
  type        = string
  description = "選填。要轉送到外部 SIEM 的 Pub/Sub Topic 名稱，留空則不建立 Pub/Sub Sink。"
  default     = ""
}

variable "audit_configs" {
  description = <<-EOT
    Organization 層級的 Data Access Audit Log 設定（IAM auditConfigs，
    不是 Organization Policy constraint，見最外層 README.md 4.1 節的警告）。
    key = service name（例如 "storage.googleapis.com"，或 "allServices"
    代表全部服務），value = 要開啟的 log_type 清單
    （"ADMIN_READ" / "DATA_READ" / "DATA_WRITE"）。
    留空（預設）代表不主動開啟任何 Data Access log，沿用 Google 預設值
    （BigQuery 除外，BigQuery 的 Data Access log 一律開啟、無法關閉）。
  EOT
  type        = map(list(string))
  default     = {}
}
