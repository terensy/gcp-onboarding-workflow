locals {
  catalog_path = coalesce(var.catalog_path, "${path.module}/../../policies_catalog.yaml")
  catalog_raw  = yamldecode(file(local.catalog_path))
  catalog      = { for p in local.catalog_raw.policies : p.id => p }

  # 只有 type 已確認為 boolean / list 的政策才可能被納入管理；
  # "unverified" 一律被擋下，避免對 value 形狀的錯誤猜測被套用到正式環境。
  manageable_catalog = {
    for id, p in local.catalog : id => p
    if try(p.attach_level, "organization") == "organization" && p.type != "unverified"
  }

  # enabled_policy_ids 非空時採白名單模式，忽略 catalog 的 enabled 欄位；
  # 否則沿用每條政策自帶的 enabled: true/false。
  org_level_policies = {
    for id, p in local.manageable_catalog : id => p
    if length(var.enabled_policy_ids) > 0 ? contains(var.enabled_policy_ids, id) : try(p.enabled, false)
  }

  # 文件對照用：被目錄收錄、但因 type = unverified 而未被實際管理的 constraint id。
  unmanaged_unverified_ids = sort([
    for id, p in local.catalog : id
    if p.type == "unverified"
  ])
}

# ---------------------------------------------------------------------------
# Organization 層級政策
# ---------------------------------------------------------------------------
resource "google_org_policy_policy" "org" {
  for_each = local.org_level_policies

  name   = "organizations/${var.org_id}/policies/${each.key}"
  parent = "organizations/${var.org_id}"

  spec {
    rules {
      enforce = each.value.type == "boolean" ? (try(each.value.default_enforce, true) ? "TRUE" : "FALSE") : null

      allow_all = each.value.type == "list" && try(each.value.default_mode, "") == "allow_all" ? "TRUE" : null
      deny_all  = each.value.type == "list" && try(each.value.default_mode, "") == "deny_all" ? "TRUE" : null

      dynamic "values" {
        for_each = each.value.type == "list" && contains(["allow_values", "deny_values"], try(each.value.default_mode, "")) ? [1] : []
        content {
          allowed_values = try(each.value.default_mode, "") == "allow_values" ? lookup(var.value_overrides, each.key, try(each.value.default_values, [])) : null
          denied_values  = try(each.value.default_mode, "") == "deny_values" ? lookup(var.value_overrides, each.key, try(each.value.default_values, [])) : null
        }
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Folder 層級例外（CIS 1.1.3：按環境／敏感度分 folder 覆寫政策）
# ---------------------------------------------------------------------------
resource "google_org_policy_policy" "folder" {
  for_each = var.folder_overrides

  name   = "folders/${each.value.folder_id}/policies/${each.value.policy_id}"
  parent = "folders/${each.value.folder_id}"

  spec {
    rules {
      enforce   = each.value.rule_type == "enforce" ? (coalesce(each.value.bool_value, true) ? "TRUE" : "FALSE") : null
      allow_all = each.value.rule_type == "allow_all" ? "TRUE" : null
      deny_all  = each.value.rule_type == "deny_all" ? "TRUE" : null

      dynamic "values" {
        for_each = contains(["allowed_values", "denied_values"], each.value.rule_type) ? [1] : []
        content {
          allowed_values = each.value.rule_type == "allowed_values" ? each.value.values : null
          denied_values  = each.value.rule_type == "denied_values" ? each.value.values : null
        }
      }
    }
  }
}
