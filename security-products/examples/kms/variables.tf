variable "project_id" {
  type        = string
  description = "存放 Key Ring 的 Project ID——建議是集中管理的 KMS Project，不是各 Workload Project 自己開，見最外層 README.md 5.3 節。"
}

variable "location" {
  type        = string
  description = "Key Ring 所在地區，通常要跟被保護的資源同區域。"
  default     = "asia-east1"
}

variable "key_ring_name" {
  type    = string
  default = "kr-cmek"
}

variable "key_name" {
  type    = string
  default = "key-cmek-default"
}

variable "rotation_period" {
  type        = string
  description = "自動輪替週期，格式如 \"7776000s\"（90 天）。輪替不會重新加密舊資料，見最外層 README.md 5.3 節。"
  default     = "7776000s"
}

variable "protection_level" {
  type        = string
  description = "SOFTWARE（最便宜） / HSM（FIPS 140-2 Level 3）。"
  default     = "SOFTWARE"

  validation {
    condition     = contains(["SOFTWARE", "HSM"], var.protection_level)
    error_message = "protection_level 必須是 SOFTWARE 或 HSM。"
  }
}

variable "cmek_user_member" {
  type        = string
  description = "要授予「使用這把 CMEK 加解密」權限的 principal，例如某服務的 Service Agent：\"serviceAccount:service-PROJECT_NUMBER@gs-project-accounts.iam.gserviceaccount.com\"。"
}
