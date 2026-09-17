# HA VPN Gateway——2 個 interface，跟地端建立 2 條 tunnel 才能達到 99.99% SLA。
# 對應最外層 README.md 3.2 節「Cloud VPN (HA VPN)」。
resource "google_compute_ha_vpn_gateway" "this" {
  project = var.host_project_id
  name    = var.vpn_gateway_name
  region  = var.region
  network = var.network_self_link
}

# 專用的 Cloud Router，跟 shared_vpc module 給 Cloud NAT 用的 Router 分開，
# 避免 VPN 的 BGP 設定跟 NAT 的設定互相牽動。
resource "google_compute_router" "vpn_router" {
  project = var.host_project_id
  name    = "rtr-vpn-${var.vpn_gateway_name}"
  region  = var.region
  network = var.network_self_link

  bgp {
    asn = var.cloud_router_asn
  }
}

# 代表地端 VPN 設備的資源，IP 位址依 peer_external_ips 的數量決定 redundancy_type。
resource "google_compute_external_vpn_gateway" "peer" {
  name            = var.peer_gateway_name
  redundancy_type = length(var.peer_external_ips) == 2 ? "TWO_IPS_REDUNDANT" : "SINGLE_IP_INTERNALLY_REDUNDANT"

  dynamic "interface" {
    for_each = var.peer_external_ips
    content {
      id         = interface.key
      ip_address = interface.value
    }
  }
}

resource "google_compute_vpn_tunnel" "tunnels" {
  for_each = var.tunnels

  project                         = var.host_project_id
  region                          = var.region
  name                            = "vpn-${each.key}"
  vpn_gateway                     = google_compute_ha_vpn_gateway.this.id
  vpn_gateway_interface           = each.value.vpn_gateway_interface
  peer_external_gateway           = google_compute_external_vpn_gateway.peer.id
  peer_external_gateway_interface = each.value.peer_gateway_interface
  shared_secret                   = var.tunnel_shared_secrets[each.key]
  router                          = google_compute_router.vpn_router.id
  ike_version                     = 2
}

resource "google_compute_router_interface" "tunnels" {
  for_each = var.tunnels

  project    = var.host_project_id
  region     = var.region
  name       = "if-${each.key}"
  router     = google_compute_router.vpn_router.name
  ip_range   = each.value.cloud_router_bgp_ip_range
  vpn_tunnel = google_compute_vpn_tunnel.tunnels[each.key].name
}

resource "google_compute_router_peer" "tunnels" {
  for_each = var.tunnels

  project         = var.host_project_id
  region          = var.region
  name            = "bgp-${each.key}"
  router          = google_compute_router.vpn_router.name
  interface       = google_compute_router_interface.tunnels[each.key].name
  peer_asn        = var.peer_asn
  peer_ip_address = each.value.peer_bgp_ip_address
}
