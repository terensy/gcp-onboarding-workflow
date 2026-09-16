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
