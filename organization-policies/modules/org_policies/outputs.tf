output "org_level_policy_names" {
  description = "已建立的 organization 層級 google_org_policy_policy 完整資源名稱。"
  value       = { for k, v in google_org_policy_policy.org : k => v.name }
}

output "folder_level_policy_names" {
  description = "已建立的 folder 層級 google_org_policy_policy 完整資源名稱。"
  value       = { for k, v in google_org_policy_policy.folder : k => v.name }
}

output "unmanaged_unverified_policies" {
  description = <<-EOT
    Catalog 中標記為 type = unverified 而被 module 主動跳過的 constraint id
    （多為 Google 自動強制的政策）。用
      gcloud org-policies describe constraints/<id> --organization=ORG_ID --effective
    核對 schema 後，把 catalog 對應項目的 type 改成 boolean 或 list，
    即可讓下次 terraform plan 將其納入管理。
  EOT
  value       = local.unmanaged_unverified_ids
}
