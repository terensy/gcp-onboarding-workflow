module "shared_vpc" {
  source = "../../modules/shared_vpc"

  host_project_id     = var.host_project_id
  service_project_ids = var.service_project_ids
  subnets             = var.subnets
}

module "hierarchical_firewall" {
  source = "../../modules/hierarchical_firewall"

  parent_type  = "organization"
  parent_id    = var.org_id
  catalog_path = "${path.module}/../../firewall_baseline_catalog.yaml"
}

# 是否要接地端連線，見最外層 README.md 3.2 節。預設 false——沒有混合雲需求的話
# 不需要建立 VPN，enable_vpn = true 才會實際建立 HA VPN Gateway/Tunnel/BGP。
module "cloud_vpn" {
  count  = var.enable_vpn ? 1 : 0
  source = "../../modules/cloud_vpn"

  host_project_id   = var.host_project_id
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

output "network_id" {
  value = module.shared_vpc.network_id
}

output "subnet_self_links" {
  value = module.shared_vpc.subnet_self_links
}

output "nat_gateway_names" {
  value = module.shared_vpc.nat_gateway_names
}

output "firewall_policy_id" {
  value = module.hierarchical_firewall.policy_id
}

output "vpn_gateway_interfaces" {
  description = "HA VPN Gateway 的公開 IP，要提供給地端設備設定 peer IP；enable_vpn = false 時為 null。"
  value       = var.enable_vpn ? module.cloud_vpn[0].vpn_gateway_interfaces : null
}

output "vpn_tunnel_status" {
  description = "各 VPN tunnel 的建立狀態；enable_vpn = false 時為 null。"
  value       = var.enable_vpn ? module.cloud_vpn[0].tunnel_status : null
}
