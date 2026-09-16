module "org_policies" {
  source = "../../modules/org_policies"

  org_id       = var.org_id
  catalog_path = "${path.module}/../../policies_catalog.yaml"

  value_overrides = {
    "iam.allowedPolicyMemberDomains" = var.allowed_customer_ids
    "gcp.resourceLocations"          = var.allowed_resource_locations
  }

  folder_overrides = var.folder_overrides
}

output "org_level_policy_names" {
  value = module.org_policies.org_level_policy_names
}

output "folder_level_policy_names" {
  value = module.org_policies.folder_level_policy_names
}

output "unmanaged_unverified_policies" {
  value = module.org_policies.unmanaged_unverified_policies
}
