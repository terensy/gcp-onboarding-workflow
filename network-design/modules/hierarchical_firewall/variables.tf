variable "parent_type" {
  type        = string
  description = "階層式防火牆政策要掛在哪一層：organization 或 folder。"

  validation {
    condition     = contains(["organization", "folder"], var.parent_type)
    error_message = "parent_type 必須是 organization 或 folder。"
  }
}

variable "parent_id" {
  type        = string
  description = "parent_type = organization 時填 Organization ID；folder 時填 Folder 數字 ID。"
}

variable "policy_short_name" {
  type        = string
  description = "防火牆政策的名稱（短名稱，符合 GCP 資源命名規則）。"
  default     = "baseline-firewall-policy"
}

variable "catalog_path" {
  type        = string
  description = <<-EOT
    firewall_baseline_catalog.yaml 的路徑。留空（null）則預設讀取
    module 目錄往上兩層的 firewall_baseline_catalog.yaml（即 repo 根目錄）。
  EOT
  default     = null
}

variable "extra_rules" {
  description = <<-EOT
    catalog 沒收錄、只有貴組織需要的額外規則，格式同 catalog 裡的每一筆。
    key 僅供識別。
  EOT
  type = map(object({
    priority    = number
    direction   = string
    action      = string
    description = string
    ip_ranges   = list(string)
    layer4_configs = list(object({
      ip_protocol = string
      ports       = optional(list(string))
    }))
  }))
  default = {}
}
