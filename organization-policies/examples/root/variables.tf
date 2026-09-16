variable "org_id" {
  type        = string
  description = "GCP Organization ID，例如 \"123456789012\"。"
}

variable "allowed_customer_ids" {
  type        = list(string)
  description = "iam.allowedPolicyMemberDomains 允許的 Cloud Identity Customer ID（格式 C0xxxxxxx）。"
  default     = []
}

variable "allowed_resource_locations" {
  type        = list(string)
  description = "gcp.resourceLocations 允許的核准地區或地區群組，例如 [\"in:asia-east1-locations\"]。"
  default     = []
}

variable "folder_overrides" {
  type = map(object({
    folder_id  = string
    policy_id  = string
    rule_type  = string
    bool_value = optional(bool)
    values     = optional(list(string))
  }))
  description = "傳入 module 的 folder 層級例外設定，詳見 modules/org_policies/variables.tf。"
  default     = {}
}
