# ---------------------------------------------------------------------------
# Terraform State——版本控制、不留在任何人的筆電本機。
# ---------------------------------------------------------------------------
resource "google_storage_bucket" "tf_state" {
  project                     = var.seed_project_id
  name                        = var.state_bucket_name
  location                    = var.state_bucket_location
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = var.state_version_retention_count
    }
    action {
      type = "Delete"
    }
  }
}

# ---------------------------------------------------------------------------
# Workload Identity Federation——CI/CD 用短期憑證登入 GCP，不下載
# Service Account 金鑰檔案。
# ---------------------------------------------------------------------------
resource "google_iam_workload_identity_pool" "cicd" {
  project                   = var.cicd_project_id
  workload_identity_pool_id = var.wif_pool_id
  display_name              = "Terraform CI/CD"
  description               = "Workload Identity Pool for CI/CD pipelines applying this repo's Terraform"
}

resource "google_iam_workload_identity_pool_provider" "github_actions" {
  project                            = var.cicd_project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.cicd.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions"
  display_name                       = "GitHub Actions"

  # 只允許指定的 repository 換發憑證，避免任何 GitHub repo 都能冒用這個 Pool。
  attribute_condition = "assertion.repository == \"${var.github_repository}\""

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "cicd" {
  project      = var.cicd_project_id
  account_id   = var.cicd_service_account_id
  display_name = "Terraform CI/CD"
  description  = "Impersonated via Workload Identity Federation by GitHub Actions — no downloaded key file."
}

resource "google_service_account_iam_member" "wif_binding" {
  service_account_id = google_service_account.cicd.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.cicd.name}/attribute.repository/${var.github_repository}"
}

resource "google_storage_bucket_iam_member" "cicd_state_access" {
  bucket = google_storage_bucket.tf_state.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.cicd.email}"
}
