variable "host_project_id" {
  type        = string
  description = "HA VPN Gateway 要建立在哪個 Project（通常是 shared_vpc 的 host_project_id）。"
}

variable "network_self_link" {
  type        = string
  description = "要接 VPN 的 VPC 網路 self_link，通常是 shared_vpc module 的 network_self_link output。"
}

variable "region" {
  type        = string
  description = "HA VPN Gateway 與 Cloud Router 所在 Region。"
}

variable "vpn_gateway_name" {
  type        = string
  description = "HA VPN Gateway 名稱。"
  default     = "ha-vpn-gw"
}

variable "cloud_router_asn" {
  type        = number
  description = "Google Cloud 端 Cloud Router 的 ASN，須與地端使用的 ASN 不同。"
  default     = 64514
}

variable "peer_gateway_name" {
  type        = string
  description = "代表地端（on-prem）VPN 設備的 external VPN gateway 資源名稱。"
}

variable "peer_asn" {
  type        = number
  description = "地端 VPN 設備的 BGP ASN。"
}

variable "peer_external_ips" {
  type        = list(string)
  description = <<-EOT
    地端 VPN 設備對外的公開 IP。填 2 個會建立 TWO_IPS_REDUNDANT（建議，兩台地端設備
    各自獨立，才能達到 HA VPN 99.99% SLA）；只有 1 個地端設備時填 1 個 IP，
    會建立 SINGLE_IP_INTERNALLY_REDUNDANT（SLA 降為 99.9%）。
  EOT

  validation {
    condition     = length(var.peer_external_ips) == 1 || length(var.peer_external_ips) == 2
    error_message = "peer_external_ips 必須填 1 或 2 個 IP。"
  }
}

variable "tunnels" {
  description = <<-EOT
    VPN Tunnel 設定，key 建議用 tunnel-0 / tunnel-1。要達到 HA VPN 99.99% SLA
    必須建立 2 條 tunnel，分別接 Cloud Router 兩個 interface（0 / 1）與地端的兩個
    interface；每條 tunnel 各自的 BGP session 用一組 /30 的 link-local 位址
    （例如 169.254.0.0/30、169.254.1.0/30），不要重複使用同一段。

      vpn_gateway_interface     = 這條 tunnel 接 HA VPN Gateway 的哪個 interface（0 或 1）
      peer_gateway_interface    = 這條 tunnel 接地端 external gateway 的哪個 interface
                                  （SINGLE_IP_INTERNALLY_REDUNDANT 時兩條 tunnel 都填 0）
      cloud_router_bgp_ip_range = Cloud Router 這端的 BGP 介面 IP，CIDR 格式，例如 "169.254.0.1/30"
      peer_bgp_ip_address       = 地端這端的 BGP 介面 IP，例如 "169.254.0.2"

    每條 tunnel 的 IKE 共用金鑰不放在這裡，而是用 key 相同的 var.tunnel_shared_secrets
    另外帶入——這個變數不能標成 sensitive，否則 Terraform 無法把它當 for_each 的 key 使用。
  EOT
  type = map(object({
    vpn_gateway_interface     = number
    peer_gateway_interface    = number
    cloud_router_bgp_ip_range = string
    peer_bgp_ip_address       = string
  }))

  validation {
    condition     = length(var.tunnels) > 0
    error_message = "至少要設定一條 tunnel；建議設定兩條以達到 HA VPN 的 99.99% SLA。"
  }
}

variable "tunnel_shared_secrets" {
  description = <<-EOT
    每條 tunnel 的 IKE 共用金鑰，key 必須跟 var.tunnels 的 key 一一對應。
    敏感資訊，建議用 TF_VAR_tunnel_shared_secrets 環境變數或 Secret Manager 帶入，
    不要明文寫進 terraform.tfvars 並提交到版控。
  EOT
  type        = map(string)
  sensitive   = true
}
