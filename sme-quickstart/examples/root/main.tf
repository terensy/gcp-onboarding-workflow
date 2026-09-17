locals {
  policy_value_overrides = {
    "iam.allowedPolicyMemberDomains" = var.allowed_customer_ids
    "gcp.resourceLocations"          = var.allowed_resource_locations
  }
}

# ---------------------------------------------------------------------------
# 2.1 Folder / Project
# ---------------------------------------------------------------------------
module "resource_hierarchy" {
  source = "../../modules/resource_hierarchy"

  org_id             = var.org_id
  billing_account_id = var.billing_account_id
  labels             = var.labels

  host_project_id     = var.host_project_id
  service_project_ids = var.service_project_ids
  logging_project_id  = var.logging_project_id
}

# ---------------------------------------------------------------------------
# 2.2 Organization Policies —— 沿用 organization-policies/ 子專案既有 module，
# 只是用 enabled_policy_ids 白名單挑一個 SME 精簡子集，catalog 本身不用複製。
# ---------------------------------------------------------------------------
module "organization_policies" {
  source = "../../../organization-policies/modules/org_policies"

  org_id             = var.org_id
  enabled_policy_ids = var.enabled_policy_ids
  value_overrides    = local.policy_value_overrides
}

# ---------------------------------------------------------------------------
# 1.2 / 2.4 IAM —— 沿用 iam-bindings/ 子專案既有 module，5 個管理群組全部保留。
# ---------------------------------------------------------------------------
module "iam_bindings" {
  source = "../../../iam-bindings/modules/iam_bindings"

  org_id             = var.org_id
  billing_account_id = var.billing_account_id

  group_emails = {
    organization_admins = "gcp-organization-admins@${var.domain}"
    billing_admins      = "gcp-billing-admins@${var.domain}"
    network_admins      = "gcp-network-admins@${var.domain}"
    security_admins     = "gcp-security-admins@${var.domain}"
    logging_admins      = "gcp-logging-admins@${var.domain}"
  }
}

# ---------------------------------------------------------------------------
# 3.1 / 3.5 網路 —— 沿用 network-design/ 子專案既有 module。
# ---------------------------------------------------------------------------
module "shared_vpc" {
  source = "../../../network-design/modules/shared_vpc"

  host_project_id     = module.resource_hierarchy.host_project_id
  service_project_ids = module.resource_hierarchy.service_project_ids
  subnets             = var.subnets
}

module "hierarchical_firewall" {
  source = "../../../network-design/modules/hierarchical_firewall"

  parent_type  = "organization"
  parent_id    = var.org_id
  catalog_path = "${path.module}/../../../network-design/firewall_baseline_catalog.yaml"
}

# 3.2 混合雲連線 —— 選用，enable_vpn 預設 false 不會產生任何資源。
module "cloud_vpn" {
  count  = var.enable_vpn ? 1 : 0
  source = "../../../network-design/modules/cloud_vpn"

  host_project_id   = module.resource_hierarchy.host_project_id
  network_self_link = module.shared_vpc.network_self_link
  region            = var.vpn_region

  vpn_gateway_name = var.vpn_gateway_name
  cloud_router_asn = var.vpn_cloud_router_asn

  peer_gateway_name = var.vpn_peer_gateway_name
  peer_asn          = var.vpn_peer_asn
  peer_external_ips = var.vpn_peer_external_ips

  tunnels               = var.vpn_tunnels
  tunnel_shared_secrets = var.vpn_tunnel_shared_secrets
}

# ---------------------------------------------------------------------------
# 4. Log 管理 —— 沿用 logging/ 子專案既有 module，只開 Cloud Storage 歸檔，
# 不開 Log Analytics（BigQuery）跟 Pub/Sub SIEM 轉送，Data Access log 也不開。
# ---------------------------------------------------------------------------
module "aggregated_logging" {
  source = "../../../logging/modules/aggregated_logging"

  org_id             = var.org_id
  logging_project_id = module.resource_hierarchy.logging_project_id

  enable_analytics_sink          = false
  enable_storage_archive_sink    = true
  storage_archive_retention_days = var.storage_archive_retention_days
  pubsub_siem_topic_name         = ""
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------
output "network_folder_id" {
  value = module.resource_hierarchy.network_folder_id
}

output "service_folder_id" {
  value = module.resource_hierarchy.service_folder_id
}

output "host_project_id" {
  value = module.resource_hierarchy.host_project_id
}

output "logging_project_id" {
  value = module.resource_hierarchy.logging_project_id
}

output "org_level_policy_names" {
  value = module.organization_policies.org_level_policy_names
}

output "organization_bindings" {
  value = module.iam_bindings.organization_bindings
}

output "network_id" {
  value = module.shared_vpc.network_id
}

output "nat_gateway_names" {
  value = module.shared_vpc.nat_gateway_names
}

output "firewall_policy_id" {
  value = module.hierarchical_firewall.policy_id
}

output "vpn_gateway_interfaces" {
  description = "HA VPN Gateway 的公開 IP；enable_vpn = false 時為 null。"
  value       = var.enable_vpn ? module.cloud_vpn[0].vpn_gateway_interfaces : null
}

output "storage_archive_bucket_name" {
  value = module.aggregated_logging.storage_archive_bucket_name
}
