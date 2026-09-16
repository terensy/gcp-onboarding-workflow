variable "org_id" {
  type        = string
  description = "GCP Organization ID，例如 \"123456789012\"。"
}

variable "catalog_path" {
  type        = string
  description = <<-EOT
    policies_catalog.yaml 的路徑。留空（null）則預設讀取
    module 目錄往上兩層的 policies_catalog.yaml（即 repo 根目錄）。
    注意：variable 的 default 不能用 path.module（僅允許常數），
    實際預設值改在 main.tf 的 local.catalog_path 用 coalesce() 組出。
  EOT
  default     = null
}

variable "enabled_policy_ids" {
  type        = set(string)
  description = <<-EOT
    要實際套用的 constraint id 白名單（僅限 organization 層級）。
    留空（預設）= 套用 catalog 中每條政策自帶的 enabled: true / false 設定。
    非空 = 忽略 catalog 的 enabled 欄位，只套用清單內列出的 id（type 仍必須
    不是 "unverified"，否則會被安全過濾機制擋下）。
  EOT
  default     = []
}

variable "value_overrides" {
  description = <<-EOT
    針對個別 constraint 覆寫 catalog 的 default_values（例如組織自己的
    Cloud Identity Customer ID、核准地區清單）。
    key = constraint id，value = 值清單。
  EOT
  type        = map(list(string))
  default     = {}
}

variable "folder_overrides" {
  description = <<-EOT
    Folder 層級的政策例外設定，對應 CIS 1.1.3「按環境／敏感度分 folder」的做法。
    key 僅供識別（會用來當 Terraform resource key），value 為：
      folder_id  = 目標 folder 的數字 ID
      policy_id  = constraint id，例如 "compute.vmExternalIpAccess"
      rule_type  = "enforce" | "allow_all" | "deny_all" | "allowed_values" | "denied_values"
      bool_value = rule_type = "enforce" 時要填的布林值
      values     = rule_type = "allowed_values" / "denied_values" 時要填的清單
  EOT
  type = map(object({
    folder_id  = string
    policy_id  = string
    rule_type  = string
    bool_value = optional(bool)
    values     = optional(list(string))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.folder_overrides :
      contains(["enforce", "allow_all", "deny_all", "allowed_values", "denied_values"], v.rule_type)
    ])
    error_message = "folder_overrides 中每一筆的 rule_type 必須是 enforce / allow_all / deny_all / allowed_values / denied_values 其中之一。"
  }
}
