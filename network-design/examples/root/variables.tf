variable "org_id" {
  type        = string
  description = "GCP Organization ID，防火牆政策掛在這裡（parent_type = organization）。"
}

variable "host_project_id" {
  type        = string
  description = "Shared VPC Host Project ID。"
}

variable "service_project_ids" {
  type        = list(string)
  description = "要附加到 Host Project 的 Service Project ID 清單。"
  default     = []
}

variable "subnets" {
  type = map(object({
    region                   = string
    ip_cidr_range            = string
    private_ip_google_access = optional(bool, true)
    secondary_ranges         = optional(map(string), {})
  }))
  description = "子網路清單，詳見 modules/shared_vpc/variables.tf。"
}

# ---------------------------------------------------------------------------
# Cloud VPN（HA VPN）——是否要接地端網路，見最外層 README.md 3.2 節。
# 沒有混合雲需求時，enable_vpn 留預設值 false 即可，以下變數都不需要填。
# ---------------------------------------------------------------------------
variable "enable_vpn" {
  type        = bool
  description = "是否建立 Cloud VPN（HA VPN）連回地端網路。預設 false。"
  default     = false
}

variable "vpn_region" {
  type        = string
  description = "enable_vpn = true 時，HA VPN Gateway 所在 Region。"
  default     = ""
}

variable "vpn_gateway_name" {
  type        = string
  description = "HA VPN Gateway 名稱。"
  default     = "ha-vpn-gw"
}

variable "vpn_cloud_router_asn" {
  type        = number
  description = "Google Cloud 端 Cloud Router 的 ASN，須與地端使用的 ASN 不同。"
  default     = 64514
}

variable "vpn_peer_gateway_name" {
  type        = string
  description = "代表地端 VPN 設備的 external VPN gateway 資源名稱。"
  default     = ""
}

variable "vpn_peer_asn" {
  type        = number
  description = "地端 VPN 設備的 BGP ASN。"
  default     = 65000
}

variable "vpn_peer_external_ips" {
  type        = list(string)
  description = "地端 VPN 設備對外的公開 IP，1 或 2 個，詳見 modules/cloud_vpn/variables.tf。"
  default     = []
}

variable "vpn_tunnels" {
  description = "VPN Tunnel 設定（不含共用金鑰），詳見 modules/cloud_vpn/variables.tf。"
  type = map(object({
    vpn_gateway_interface     = number
    peer_gateway_interface    = number
    cloud_router_bgp_ip_range = string
    peer_bgp_ip_address       = string
  }))
  default = {}
}

variable "vpn_tunnel_shared_secrets" {
  description = <<-EOT
    每條 tunnel 的 IKE 共用金鑰，key 需對應 var.vpn_tunnels。敏感資訊，
    建議用 TF_VAR_vpn_tunnel_shared_secrets 環境變數帶入，不要寫進 terraform.tfvars。
  EOT
  type        = map(string)
  sensitive   = true
  default     = {}
}
