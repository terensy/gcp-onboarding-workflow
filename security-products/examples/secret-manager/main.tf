resource "google_secret_manager_secret" "this" {
  project   = var.project_id
  secret_id = var.secret_id

  replication {
    auto {}
  }

  dynamic "rotation" {
    for_each = var.enable_rotation_notification ? [1] : []
    content {
      rotation_period    = var.rotation_period
      next_rotation_time = var.next_rotation_time
    }
  }

  dynamic "topics" {
    for_each = var.enable_rotation_notification ? [1] : []
    content {
      name = var.rotation_notification_topic_id
    }
  }
}

# 實際密文版本要透過 CI/CD 或 gcloud 另外寫入
# （gcloud secrets versions add SECRET_ID --data-file=...），
# 不建議把密文明文寫進 Terraform 程式碼或 tfvars。

resource "google_secret_manager_secret_iam_member" "accessor" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.this.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = var.accessor_member
}

output "secret_id" {
  value = google_secret_manager_secret.this.secret_id
}
