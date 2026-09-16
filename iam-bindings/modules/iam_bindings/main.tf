locals {
  catalog_path = coalesce(var.catalog_path, "${path.module}/../../bindings_catalog.yaml")
  catalog_raw  = yamldecode(file(local.catalog_path))

  # catalog 裡同一個 group_key 會出現多筆（一個群組綁多個角色），
  # 用 "group_key.role" 當 for_each key 確保唯一。
  catalog_bindings = {
    for b in local.catalog_raw.bindings :
    "${b.group_key}.${b.role}" => merge(b, {
      member = "group:${var.group_emails[b.group_key]}"
    })
  }

  org_level_bindings = {
    for k, b in local.catalog_bindings : k => b
    if b.scope == "organization"
  }

  billing_level_bindings = {
    for k, b in local.catalog_bindings : k => b
    if b.scope == "billing_account" && var.billing_account_id != ""
  }

  extra_org_bindings = {
    for k, b in var.extra_bindings : k => b
    if b.scope == "organization"
  }

  extra_folder_bindings = {
    for k, b in var.extra_bindings : k => b
    if b.scope == "folder"
  }

  extra_project_bindings = {
    for k, b in var.extra_bindings : k => b
    if b.scope == "project"
  }

  extra_billing_bindings = {
    for k, b in var.extra_bindings : k => b
    if b.scope == "billing_account"
  }
}

# ---------------------------------------------------------------------------
# Organization 層級（catalog 驅動）
# ---------------------------------------------------------------------------
resource "google_organization_iam_member" "catalog" {
  for_each = local.org_level_bindings

  org_id = var.org_id
  role   = each.value.role
  member = each.value.member
}

# ---------------------------------------------------------------------------
# Billing Account 層級（catalog 驅動）——注意這是獨立於 Org/Folder/Project 的
# 資源階層，Billing Account Administrator 綁在這裡才會生效。
# ---------------------------------------------------------------------------
resource "google_billing_account_iam_member" "catalog" {
  for_each = local.billing_level_bindings

  billing_account_id = var.billing_account_id
  role               = each.value.role
  member             = each.value.member
}

# ---------------------------------------------------------------------------
# 額外 binding（tfvars 傳入，catalog 沒收錄、只有貴組織需要的例外）
# ---------------------------------------------------------------------------
resource "google_organization_iam_member" "extra" {
  for_each = local.extra_org_bindings

  org_id = var.org_id
  role   = each.value.role
  member = each.value.member
}

resource "google_folder_iam_member" "extra" {
  for_each = local.extra_folder_bindings

  folder = "folders/${each.value.resource_id}"
  role   = each.value.role
  member = each.value.member
}

resource "google_project_iam_member" "extra" {
  for_each = local.extra_project_bindings

  project = each.value.resource_id
  role    = each.value.role
  member  = each.value.member
}

resource "google_billing_account_iam_member" "extra" {
  for_each = local.extra_billing_bindings

  # coalesce() 只會跳過 null，跳不過空字串，而 resource_id 的 default 是
  # ""，所以這裡要用三元運算子手動 fallback 回 var.billing_account_id。
  billing_account_id = each.value.resource_id != "" ? each.value.resource_id : var.billing_account_id
  role               = each.value.role
  member             = each.value.member
}
