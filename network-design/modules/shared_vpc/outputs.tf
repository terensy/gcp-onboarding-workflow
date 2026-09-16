output "network_id" {
  description = "Shared VPC 網路的完整資源 ID。"
  value       = google_compute_network.shared_vpc.id
}

output "network_self_link" {
  description = "Shared VPC 網路的 self_link。"
  value       = google_compute_network.shared_vpc.self_link
}

output "subnet_ids" {
  description = "各子網路名稱對應的完整資源 ID。"
  value       = { for k, v in google_compute_subnetwork.subnets : k => v.id }
}

output "subnet_self_links" {
  description = "各子網路名稱對應的 self_link，給 GKE/VM 等資源的 subnetwork 欄位使用。"
  value       = { for k, v in google_compute_subnetwork.subnets : k => v.self_link }
}

output "nat_gateway_names" {
  description = "已建立的 Cloud NAT gateway，依 Region 列出。"
  value       = { for k, v in google_compute_router_nat.nat : k => v.name }
}
