output "network_folder_id" {
  description = "network Folder 的數字 ID。"
  value       = google_folder.network.folder_id
}

output "service_folder_id" {
  description = "service Folder 的數字 ID。"
  value       = google_folder.service.folder_id
}

output "host_project_id" {
  description = "Shared VPC Host Project ID，給 network-design/modules/shared_vpc 的 host_project_id 使用。"
  value       = google_project.host.project_id
}

output "service_project_ids" {
  description = "Workload/Service Project ID 清單，給 network-design/modules/shared_vpc 的 service_project_ids 使用。"
  value       = [for p in google_project.service : p.project_id]
}

output "logging_project_id" {
  description = "集中稽核用 Logging Project ID，給 logging/modules/aggregated_logging 的 logging_project_id 使用。"
  value       = google_project.logging.project_id
}
