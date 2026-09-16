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
