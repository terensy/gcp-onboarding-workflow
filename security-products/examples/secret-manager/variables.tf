variable "project_id" {
  type        = string
  description = "Secret 所在的 Project ID。"
}

variable "secret_id" {
  type    = string
  default = "example-secret"
}

variable "accessor_member" {
  type        = string
  description = "要授予「讀取密文內容」權限的 principal，通常是應用程式用的 Service Account：\"serviceAccount:app-sa@PROJECT_ID.iam.gserviceaccount.com\"。"
}

variable "enable_rotation_notification" {
  type        = bool
  description = "是否開啟輪替排程通知（Pub/Sub）。實際輪替邏輯（換掉來源系統的密碼、寫入新版本）要另外用 Cloud Run/Cloud Functions 接這個通知自己實作，見最外層 README.md 5.4 節。"
  default     = false
}

variable "rotation_period" {
  type        = string
  description = "輪替通知週期，格式如 \"2592000s\"（30 天）。enable_rotation_notification = true 時才會生效。"
  default     = "2592000s"
}

variable "rotation_notification_topic_id" {
  type        = string
  description = "輪替通知要發到的 Pub/Sub Topic 完整 ID。enable_rotation_notification = true 時必填。"
  default     = ""
}

variable "next_rotation_time" {
  type        = string
  description = <<-EOT
    下一次輪替通知的時間（RFC3339 格式）。enable_rotation_notification = true
    時必填。這個欄位需要人工/外部流程定期往後推進——不要用 timestamp() 這類
    每次 apply 都會變動的函式帶入，會讓 Terraform 每次 plan 都顯示這個資源
    有變更。
  EOT
  default     = ""
}
