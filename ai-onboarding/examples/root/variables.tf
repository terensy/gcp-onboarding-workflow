variable "project_id" {
  type        = string
  description = "Model Armor Template 與 DLP Template 要建立在哪個 Project。"
}

variable "location" {
  type        = string
  description = "Model Armor Template 與 DLP Template 的地區。"
  default     = "us-central1"
}

variable "enforcement_type" {
  type        = string
  description = <<-EOT
    INSPECT_ONLY（dry-run，只記錄不擋）或 INSPECT_AND_BLOCK（實際擋下）。
    第一次套用建議保持預設的 INSPECT_ONLY，觀察一輪 Finding 都是預期內的
    違規之後，再手動改成 INSPECT_AND_BLOCK。
  EOT
  default     = "INSPECT_ONLY"
}
