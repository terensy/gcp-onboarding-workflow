# 兩個 Folder：network 放 Shared VPC Host Project，service 放 Workload/Service
# Project，不做環境（dev/prod）或子公司細分——這是刻意簡化過的兩層結構，
# 對應最外層 README.md 2.1 節「Folder 階層規劃沒有一定的答案」的取捨。
resource "google_folder" "network" {
  display_name = var.network_folder_display_name
  parent       = "organizations/${var.org_id}"
}

resource "google_folder" "service" {
  display_name = var.service_folder_display_name
  parent       = "organizations/${var.org_id}"
}

resource "google_project" "host" {
  project_id      = var.host_project_id
  name            = var.host_project_id
  folder_id       = google_folder.network.folder_id
  billing_account = var.billing_account_id
  labels          = var.labels
}

resource "google_project" "service" {
  for_each = toset(var.service_project_ids)

  project_id      = each.value
  name            = each.value
  folder_id       = google_folder.service.folder_id
  billing_account = var.billing_account_id
  labels          = var.labels
}

# 直接掛在 Organization 底下（org_id，不是 folder_id）——見 variables.tf 的說明，
# 這是刻意的權限邊界設計，不要為了「跟其他 Project 放在一起比較整齊」而改成
# 塞進 network 或 service Folder。
resource "google_project" "logging" {
  project_id      = var.logging_project_id
  name            = var.logging_project_id
  org_id          = var.org_id
  billing_account = var.billing_account_id
  labels          = var.labels
}
