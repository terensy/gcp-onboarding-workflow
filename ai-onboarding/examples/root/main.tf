module "ai_guardrails" {
  source = "../../modules/ai_guardrails"

  project_id       = var.project_id
  location         = var.location
  enforcement_type = var.enforcement_type
}

output "model_armor_template_name" {
  value = module.ai_guardrails.model_armor_template_name
}

output "pii_inspect_template_name" {
  value = module.ai_guardrails.pii_inspect_template_name
}

output "pii_deidentify_template_name" {
  value = module.ai_guardrails.pii_deidentify_template_name
}
