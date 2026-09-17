output "model_armor_template_id" {
  description = "Model Armor Template 的完整資源 ID。"
  value       = google_model_armor_template.baseline.id
}

output "model_armor_template_name" {
  description = "Model Armor Template 的資源名稱（projects/.../locations/.../templates/...），掛到 Vertex AI 或 Apigee 時需要。"
  value       = google_model_armor_template.baseline.name
}

output "pii_inspect_template_name" {
  description = "PII Inspect Template 資源名稱，供其他 DLP job（例如未來「進階資料治理」的 RAG data lake 掃描）重複使用。"
  value       = google_data_loss_prevention_inspect_template.pii_baseline.name
}

output "pii_deidentify_template_name" {
  description = "PII De-identify Template 資源名稱。"
  value       = google_data_loss_prevention_deidentify_template.pii_baseline.name
}
