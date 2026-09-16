variable "seed_project_id" {
  type        = string
  description = "存放 Terraform State Bucket 的 Project ID。"
}

variable "cicd_project_id" {
  type        = string
  description = "存放 WIF Pool 與 CI/CD Service Account 的 Project ID。"
}

variable "state_bucket_name" {
  type        = string
  description = "Terraform State Bucket 名稱（全域唯一）。"
}

variable "github_repository" {
  type        = string
  description = "允許透過 WIF 認證的 GitHub repository，格式 \"org/repo\"。"
}
