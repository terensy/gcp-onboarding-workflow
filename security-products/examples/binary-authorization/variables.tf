variable "project_id" {
  type        = string
  description = "Attestor 與 Policy 所在的 Project ID。"
}

variable "attestor_name" {
  type    = string
  default = "built-by-approved-pipeline"
}

variable "note_name" {
  type    = string
  default = "built-by-approved-pipeline-note"
}

variable "attestor_display_name" {
  type    = string
  default = "Built by approved CI/CD pipeline"
}

variable "pgp_public_key_id" {
  type        = string
  description = "簽章用金鑰的 Key ID（例如用 gpg --list-keys 取得）。"
}

variable "pgp_public_key" {
  type        = string
  description = "ASCII-armored PGP 公鑰內容，用來驗證簽章。"
}

variable "enforcement_mode" {
  type        = string
  description = "ENFORCED_BLOCK_AND_AUDIT_LOG（擋掉不合規部署）或 DRYRUN_AUDIT_LOG_ONLY（只記錄不擋，適合分階段導入）。"
  default     = "DRYRUN_AUDIT_LOG_ONLY"

  validation {
    condition     = contains(["ENFORCED_BLOCK_AND_AUDIT_LOG", "DRYRUN_AUDIT_LOG_ONLY"], var.enforcement_mode)
    error_message = "enforcement_mode 必須是 ENFORCED_BLOCK_AND_AUDIT_LOG 或 DRYRUN_AUDIT_LOG_ONLY。"
  }
}
