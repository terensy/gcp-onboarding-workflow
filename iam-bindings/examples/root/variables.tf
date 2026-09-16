variable "org_id" {
  type        = string
  description = "GCP Organization ID，例如 \"123456789012\"。"
}

variable "billing_account_id" {
  type        = string
  description = "Cloud Billing 帳戶 ID，例如 \"012345-6789AB-CDEF01\"。"
  default     = ""
}

variable "domain" {
  type        = string
  description = "貴組織的 Cloud Identity 網域，例如 \"example.com\"，用來組出 5 個管理群組的 email。"
}

variable "extra_bindings" {
  type = map(object({
    scope       = string
    resource_id = optional(string, "")
    role        = string
    member      = string
  }))
  description = "傳入 module 的額外 IAM binding，詳見 modules/iam_bindings/variables.tf。"
  default     = {}
}
