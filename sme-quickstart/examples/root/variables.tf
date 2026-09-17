variable "org_id" {
  type        = string
  description = "GCP Organization ID，例如 \"123456789012\"。"
}

variable "domain" {
  type        = string
  description = "貴組織的 Cloud Identity 網域，例如 \"example.com\"，用來組出 5 個管理群組的 email。"
}

variable "billing_account_id" {
  type        = string
  description = "Cloud Billing 帳戶 ID，例如 \"012345-6789AB-CDEF01\"。"
}

variable "labels" {
  type        = map(string)
  description = "套用到這裡建立的每個 Project 的 Labels，見最外層 README.md 8.1 節。"
  default     = {}
}

# ---------------------------------------------------------------------------
# 2.1 Folder / Project — network / service 兩個 Folder + 1 個獨立 Logging Project
# ---------------------------------------------------------------------------
variable "host_project_id" {
  type        = string
  description = "Shared VPC Host Project ID，會建立在 network Folder 底下。"
}

variable "service_project_ids" {
  type        = list(string)
  description = "要建立的 Workload/Service Project ID 清單，會建立在 service Folder 底下。"
  default     = []
}

variable "logging_project_id" {
  type        = string
  description = "集中稽核用的 Logging Project ID，直接掛在 Organization 底下。"
}

# ---------------------------------------------------------------------------
# 2.2 Organization Policies — SME 精簡子集（8 條），詳見最外層 README.md 2.2 節
# 跟 sme-quickstart/README.md 的選用理由。要調整套用哪些政策，改這裡的
# enabled_policy_ids 即可，不需要另外複製一份 catalog。
# ---------------------------------------------------------------------------
variable "enabled_policy_ids" {
  type        = set(string)
  description = "要套用的 Organization Policy constraint id 白名單，對應 organization-policies/policies_catalog.yaml。"
  default = [
    "iam.allowedPolicyMemberDomains",
    "iam.disableServiceAccountKeyCreation",
    "compute.skipDefaultNetworkCreation",
    "compute.requireOsLogin",
    "compute.vmExternalIpAccess",
    "storage.uniformBucketLevelAccess",
    "storage.publicAccessPrevention",
    "gcp.resourceLocations",
  ]
}

variable "allowed_customer_ids" {
  type        = list(string)
  description = "iam.allowedPolicyMemberDomains 允許的 Cloud Identity Customer ID（格式 C0xxxxxxx）。"
  default     = []
}

variable "allowed_resource_locations" {
  type        = list(string)
  description = "gcp.resourceLocations 允許的核准地區或地區群組，例如 [\"in:asia-east1-locations\"]。"
  default     = []
}

# ---------------------------------------------------------------------------
# 3. 網路設計 — Shared VPC + 階層式防火牆基準線 + 選用的 Cloud VPN
# ---------------------------------------------------------------------------
variable "subnets" {
  type = map(object({
    region                   = string
    ip_cidr_range            = string
    private_ip_google_access = optional(bool, true)
    secondary_ranges         = optional(map(string), {})
  }))
  description = "子網路清單，詳見 network-design/modules/shared_vpc/variables.tf。"
}

variable "enable_vpn" {
  type        = bool
  description = "是否建立 Cloud VPN（HA VPN）連回地端網路。預設 false，沒有混合雲需求就不用理會底下的 vpn_* 變數。"
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
  description = "地端 VPN 設備對外的公開 IP，1 或 2 個，詳見 network-design/modules/cloud_vpn/variables.tf。"
  default     = []
}

variable "vpn_tunnels" {
  description = "VPN Tunnel 設定（不含共用金鑰），詳見 network-design/modules/cloud_vpn/variables.tf。"
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

# ---------------------------------------------------------------------------
# 4. Log 管理 — 只開集中式的 Cloud Storage 歸檔，不開 BigQuery/Pub/Sub
# ---------------------------------------------------------------------------
variable "storage_archive_retention_days" {
  type        = number
  description = "集中稽核 Log 在 Cloud Storage 的保留天數。"
  default     = 400
}
