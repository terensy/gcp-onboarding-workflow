module "bootstrap" {
  source = "../../modules/bootstrap"

  seed_project_id   = var.seed_project_id
  cicd_project_id   = var.cicd_project_id
  state_bucket_name = var.state_bucket_name
  github_repository = var.github_repository
}

output "state_bucket_name" {
  value = module.bootstrap.state_bucket_name
}

output "cicd_service_account_email" {
  value = module.bootstrap.cicd_service_account_email
}

output "workload_identity_provider" {
  value = module.bootstrap.workload_identity_provider
}
