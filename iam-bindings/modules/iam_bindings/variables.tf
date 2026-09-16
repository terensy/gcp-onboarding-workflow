variable "org_id" {
  type        = string
  description = "GCP Organization ID，例如 \"123456789012\"。"
}

variable "billing_account_id" {
  type        = string
  description = "Cloud Billing 帳戶 ID，例如 \"012345-6789AB-CDEF01\"。留空則跳過 scope=billing_account 的 binding。"
  default     = ""
}

variable "catalog_path" {
  type        = string
  description = <<-EOT
    bindings_catalog.yaml 的路徑。留空（null）則預設讀取
    module 目錄往上兩層的 bindings_catalog.yaml（即 repo 根目錄）。
  EOT
  default     = null
}

variable "group_emails" {
  type        = map(string)
  description = <<-EOT
    catalog 裡 group_key 對應到貴組織實際的 Google Group email。
    例如 { organization_admins = "gcp-organization-admins@example.com" }。
    catalog 本身不寫死網域，讓這份 catalog 可以跨組織重用。
  EOT
}

variable "extra_bindings" {
  description = <<-EOT
    catalog 沒收錄、只有貴組織需要的額外 binding（例如特定 folder 才需要的角色）。
    key 僅供識別，value 為：
      scope       = "organization" | "folder" | "project" | "billing_account"
      resource_id = scope 對應的資源 ID（folder 的數字 ID / project ID / billing account ID；
                    scope = organization 時可留空，直接用 var.org_id）
      role        = IAM role，例如 "roles/compute.networkAdmin"
      member      = 完整 principal 字串，例如 "group:sandbox-admins@example.com"
  EOT
  type = map(object({
    scope       = string
    resource_id = optional(string, "")
    role        = string
    member      = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.extra_bindings :
      contains(["organization", "folder", "project", "billing_account"], v.scope)
    ])
    error_message = "extra_bindings 中每一筆的 scope 必須是 organization / folder / project / billing_account 其中之一。"
  }
}
