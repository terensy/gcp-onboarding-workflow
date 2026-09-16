module "iam_bindings" {
  source = "../../modules/iam_bindings"

  org_id             = var.org_id
  billing_account_id = var.billing_account_id
  catalog_path       = "${path.module}/../../bindings_catalog.yaml"

  # catalog 裡的 group_key 對應到本組織實際的 Google Group email。
  # 對照最外層 README.md 1.2 節的群組命名範例。
  group_emails = {
    organization_admins = "gcp-organization-admins@${var.domain}"
    billing_admins      = "gcp-billing-admins@${var.domain}"
    network_admins      = "gcp-network-admins@${var.domain}"
    security_admins     = "gcp-security-admins@${var.domain}"
    logging_admins      = "gcp-logging-admins@${var.domain}"
  }

  extra_bindings = var.extra_bindings
}

output "organization_bindings" {
  value = module.iam_bindings.organization_bindings
}

output "billing_account_bindings" {
  value = module.iam_bindings.billing_account_bindings
}
