output "vpn_gateway_id" {
  description = "HA VPN Gateway 的完整資源 ID。"
  value       = google_compute_ha_vpn_gateway.this.id
}

output "vpn_gateway_interfaces" {
  description = "HA VPN Gateway 兩個 interface 對外的公開 IP，要提供給地端設備設定 peer IP。"
  value       = google_compute_ha_vpn_gateway.this.vpn_interfaces
}

output "cloud_router_name" {
  description = "VPN 專用 Cloud Router 名稱。"
  value       = google_compute_router.vpn_router.name
}

output "tunnel_names" {
  description = "各 tunnel key 對應的 VPN tunnel 名稱。"
  value       = { for k, v in google_compute_vpn_tunnel.tunnels : k => v.name }
}

output "tunnel_status" {
  description = "各 tunnel key 對應的建立狀態，套用後可用來快速確認 tunnel 有沒有起來（實際連線狀態仍需到 console 或用 gcloud 確認 IKE/BGP 是否 established）。"
  value       = { for k, v in google_compute_vpn_tunnel.tunnels : k => v.detailed_status }
}
