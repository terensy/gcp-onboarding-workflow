output "organization_bindings" {
  description = "已建立的 organization 層級 IAM binding（catalog + extra_bindings 合併後）。"
  value = merge(
    { for k, v in google_organization_iam_member.catalog : k => "${v.role} -> ${v.member}" },
    { for k, v in google_organization_iam_member.extra : k => "${v.role} -> ${v.member}" },
  )
}

output "billing_account_bindings" {
  description = "已建立的 billing account 層級 IAM binding。"
  value = merge(
    { for k, v in google_billing_account_iam_member.catalog : k => "${v.role} -> ${v.member}" },
    { for k, v in google_billing_account_iam_member.extra : k => "${v.role} -> ${v.member}" },
  )
}

output "folder_bindings" {
  description = "已建立的 folder 層級 IAM binding（僅來自 extra_bindings）。"
  value       = { for k, v in google_folder_iam_member.extra : k => "${v.role} -> ${v.member} @ ${v.folder}" }
}

output "project_bindings" {
  description = "已建立的 project 層級 IAM binding（僅來自 extra_bindings）。"
  value       = { for k, v in google_project_iam_member.extra : k => "${v.role} -> ${v.member} @ ${v.project}" }
}
