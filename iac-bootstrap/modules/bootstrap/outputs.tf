output "state_bucket_name" {
  description = "Terraform State Bucket 名稱，填進各子專案的 backend \"gcs\" 設定。"
  value       = google_storage_bucket.tf_state.name
}

output "cicd_service_account_email" {
  description = <<-EOT
    CI/CD 用的 Service Account email。這個 module 只建立 SA 本身跟 WIF
    綁定，實際要讓 CI/CD 能 apply 哪些資源，要另外把這個 SA 加進
    iam-bindings/ 的 extra_bindings（或依最小權限原則分別授權），這個
    module 刻意不自動給它 Organization Admin 之類的高權限角色。
  EOT
  value       = google_service_account.cicd.email
}

output "workload_identity_provider" {
  description = "GitHub Actions workflow 的 google-github-actions/auth 要填的 workload_identity_provider 完整路徑。"
  value       = google_iam_workload_identity_pool_provider.github_actions.name
}
