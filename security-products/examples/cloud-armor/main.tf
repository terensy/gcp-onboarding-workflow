# Cloud Armor 基準 WAF 政策範例：OWASP CRS 預先定義規則（SQLi/XSS）+
# Rate Limiting + 預設放行。掛到 Load Balancer 的 Backend Service 上才會生效
# （google_compute_backend_service.security_policy），這裡只建立政策本身。

resource "google_compute_security_policy" "this" {
  project     = var.project_id
  name        = var.policy_name
  description = "Baseline WAF policy: OWASP CRS preconfigured rules + rate limiting"

  rule {
    action      = "deny(403)"
    priority    = 1000
    description = "Block SQL injection attempts (OWASP CRS)"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-v33-stable', ['owasp-crs-v030301-id942110-sqli-sensitivity-${var.waf_sensitivity_level}'])"
      }
    }
  }

  rule {
    action      = "deny(403)"
    priority    = 1001
    description = "Block cross-site scripting attempts (OWASP CRS)"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-v33-stable')"
      }
    }
  }

  rule {
    action      = "throttle"
    priority    = 2000
    description = "Rate limit by client IP"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      enforce_on_key = "IP"
      rate_limit_threshold {
        count        = var.rate_limit_count
        interval_sec = var.rate_limit_interval_sec
      }
    }
  }

  rule {
    action      = "allow"
    priority    = 2147483647
    description = "Default allow rule"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }
}

output "security_policy_id" {
  value = google_compute_security_policy.this.id
}
