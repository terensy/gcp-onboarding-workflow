variable "seed_project_id" {
  type        = string
  description = "存放 Terraform State Bucket 的 Project ID（對應 terraform-example-foundation 的 prj-b-seed）。"
}

variable "state_bucket_name" {
  type        = string
  description = "Terraform State 用的 GCS Bucket 名稱（GCS Bucket 名稱是全域唯一，建議帶上組織/專案代號）。"
}

variable "state_bucket_location" {
  type        = string
  description = "State Bucket 所在地區。"
  default     = "asia-east1"
}

variable "state_version_retention_count" {
  type        = number
  description = "State Bucket 開啟 Versioning 後，每個物件最多保留幾個舊版本（避免版本無限累積、儲存費用一直漲）。"
  default     = 30
}

variable "cicd_project_id" {
  type        = string
  description = "存放 WIF Pool 與 CI/CD Service Account 的 Project ID（對應 terraform-example-foundation 的 prj-b-cicd）。"
}

variable "wif_pool_id" {
  type        = string
  description = "Workload Identity Pool ID。"
  default     = "cicd-pool"
}

variable "github_repository" {
  type        = string
  description = "允許透過 WIF 認證的 GitHub repository，格式 \"org/repo\"。只有這個 repo 的 GitHub Actions 能換發到對應的 Service Account 憑證。"
}

variable "cicd_service_account_id" {
  type        = string
  description = "CI/CD 用的 Service Account ID（不是完整 email，只填 account_id 部分）。"
  default     = "sa-terraform-cicd"
}
