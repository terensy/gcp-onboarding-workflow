output "policy_id" {
  description = "已建立的階層式防火牆政策完整資源 ID。"
  value       = google_compute_firewall_policy.policy.id
}

output "rule_ids" {
  description = "已建立的規則，依規則名稱列出優先權與方向，方便核對。"
  value       = { for k, v in google_compute_firewall_policy_rule.rules : k => "${v.direction} priority=${v.priority} action=${v.action}" }
}
