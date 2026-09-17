variable "org_id" {
  type        = string
  description = "GCP Organization ID，例如 \"123456789012\"。"
}

variable "billing_account_id" {
  type        = string
  description = "Cloud Billing 帳戶 ID，會連結到這裡建立的每個 Project。"
}

variable "network_folder_display_name" {
  type        = string
  description = "放 Shared VPC Host Project 的 Folder 顯示名稱。"
  default     = "network"
}

variable "service_folder_display_name" {
  type        = string
  description = "放 Workload/Service Project 的 Folder 顯示名稱。"
  default     = "service"
}

variable "host_project_id" {
  type        = string
  description = "Shared VPC Host Project 的 Project ID，會建立在 network Folder 底下。"
}

variable "service_project_ids" {
  type        = list(string)
  description = "Workload/Service Project 的 Project ID 清單，會建立在 service Folder 底下。"
  default     = []
}

variable "logging_project_id" {
  type        = string
  description = <<-EOT
    集中稽核用的 Logging Project ID。這個 Project 刻意直接掛在 Organization
    底下（不放進 network/service 任何 Folder），讓管理它的人（gcp-logging-admins@）
    跟管理一般網路/服務 Project 的人分開，避免同一群人既能寫入資源、又能竄改/
    刪除自己的稽核紀錄。
  EOT
}

variable "labels" {
  type        = map(string)
  description = "套用到這裡建立的每個 Project 的 Labels，例如 { team = \"platform\" }。"
  default     = {}
}
