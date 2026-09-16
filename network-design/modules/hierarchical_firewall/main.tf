locals {
  catalog_path = coalesce(var.catalog_path, "${path.module}/../../firewall_baseline_catalog.yaml")
  catalog_raw  = yamldecode(file(local.catalog_path))

  catalog_rules = { for r in local.catalog_raw.rules : r.name => r }
  all_rules     = merge(local.catalog_rules, var.extra_rules)

  parent = var.parent_type == "organization" ? "organizations/${var.parent_id}" : "folders/${var.parent_id}"
}

resource "google_compute_firewall_policy" "policy" {
  parent      = local.parent
  short_name  = var.policy_short_name
  description = "Hierarchical firewall baseline policy managed by network-design/ (see repo README 3.5)"
}

resource "google_compute_firewall_policy_association" "association" {
  firewall_policy   = google_compute_firewall_policy.policy.id
  attachment_target = local.parent
  name              = "${var.policy_short_name}-association"
}

resource "google_compute_firewall_policy_rule" "rules" {
  for_each = local.all_rules

  firewall_policy = google_compute_firewall_policy.policy.id
  priority        = each.value.priority
  direction       = each.value.direction
  action          = each.value.action
  description     = each.value.description
  enable_logging  = true

  match {
    src_ip_ranges  = each.value.direction == "INGRESS" ? each.value.ip_ranges : null
    dest_ip_ranges = each.value.direction == "EGRESS" ? each.value.ip_ranges : null

    dynamic "layer4_configs" {
      for_each = each.value.layer4_configs
      content {
        ip_protocol = layer4_configs.value.ip_protocol
        ports       = try(layer4_configs.value.ports, null)
      }
    }
  }
}
