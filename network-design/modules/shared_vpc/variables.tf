variable "host_project_id" {
  type        = string
  description = "要設為 Shared VPC Host Project 的 Project ID。"
}

variable "service_project_ids" {
  type        = list(string)
  description = "要附加到 Host Project 的 Service Project ID 清單。"
  default     = []
}

variable "network_name" {
  type        = string
  description = "Shared VPC 網路名稱。"
  default     = "shared-vpc"
}

variable "subnets" {
  description = <<-EOT
    子網路清單，key 為子網路名稱，value 為：
      region                    = 子網路所在 Region
      ip_cidr_range             = 主要 CIDR 範圍
      private_ip_google_access  = 是否開啟 Private Google Access（預設 true，
                                   對應最外層 README.md 3.3 節）
      secondary_ranges          = 選填，GKE Pod/Service 用的次要 IP 範圍，
                                   map(range_name => cidr)
  EOT
  type = map(object({
    region                   = string
    ip_cidr_range            = string
    private_ip_google_access = optional(bool, true)
    secondary_ranges         = optional(map(string), {})
  }))
}

variable "enable_cloud_nat" {
  type        = bool
  description = <<-EOT
    是否在每個有子網路的 Region 建立 Cloud Router + Cloud NAT，讓沒有外部 IP
    的 VM 能出網（對應最外層 README.md 3.4 節、以及 organization-policies/
    的 compute.vmExternalIpAccess 政策）。
  EOT
  default     = true
}

variable "nat_logging_filter" {
  type        = string
  description = "Cloud NAT 的 Logging 範圍：ERRORS_ONLY / TRANSLATIONS_ONLY / ALL。"
  default     = "ERRORS_ONLY"

  validation {
    condition     = contains(["ERRORS_ONLY", "TRANSLATIONS_ONLY", "ALL"], var.nat_logging_filter)
    error_message = "nat_logging_filter 必須是 ERRORS_ONLY / TRANSLATIONS_ONLY / ALL 其中之一。"
  }
}
