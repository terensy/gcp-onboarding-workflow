locals {
  nat_regions = distinct([for s in var.subnets : s.region])
}

resource "google_compute_shared_vpc_host_project" "host" {
  project = var.host_project_id
}

resource "google_compute_shared_vpc_service_project" "service" {
  for_each = toset(var.service_project_ids)

  host_project    = var.host_project_id
  service_project = each.value

  depends_on = [google_compute_shared_vpc_host_project.host]
}

resource "google_compute_network" "shared_vpc" {
  project                 = var.host_project_id
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"

  depends_on = [google_compute_shared_vpc_host_project.host]
}

resource "google_compute_subnetwork" "subnets" {
  for_each = var.subnets

  project                  = var.host_project_id
  name                     = each.key
  ip_cidr_range            = each.value.ip_cidr_range
  region                   = each.value.region
  network                  = google_compute_network.shared_vpc.id
  private_ip_google_access = each.value.private_ip_google_access

  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ranges
    content {
      range_name    = secondary_ip_range.key
      ip_cidr_range = secondary_ip_range.value
    }
  }

  # VPC Flow Logs 開啟，對應最外層 README.md 3.5 節防火牆治理的稽核需求。
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# ---------------------------------------------------------------------------
# Cloud NAT——搭配 organization-policies/ 的 compute.vmExternalIpAccess
# （關閉 VM 外部 IP）一起使用，讓沒有外部 IP 的 VM 仍能出網下載套件更新。
# ---------------------------------------------------------------------------
resource "google_compute_router" "router" {
  for_each = var.enable_cloud_nat ? toset(local.nat_regions) : []

  project = var.host_project_id
  name    = "rtr-${var.network_name}-${each.value}"
  region  = each.value
  network = google_compute_network.shared_vpc.id
}

resource "google_compute_router_nat" "nat" {
  for_each = var.enable_cloud_nat ? toset(local.nat_regions) : []

  project                            = var.host_project_id
  name                               = "nat-${var.network_name}-${each.value}"
  router                             = google_compute_router.router[each.value].name
  region                             = each.value
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = var.nat_logging_filter
  }
}
