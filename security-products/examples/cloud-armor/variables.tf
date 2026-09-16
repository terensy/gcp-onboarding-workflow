variable "project_id" {
  type        = string
  description = "Security Policy 所在的 Project ID。"
}

variable "policy_name" {
  type    = string
  default = "baseline-waf-policy"
}

variable "waf_sensitivity_level" {
  type        = number
  description = "OWASP CRS 預先定義規則的敏感度等級（0~4）。等級越高越敏感，也越容易誤擋正常流量，見最外層 README.md 5.5 節。"
  default     = 1

  validation {
    condition     = var.waf_sensitivity_level >= 0 && var.waf_sensitivity_level <= 4
    error_message = "waf_sensitivity_level 必須介於 0 到 4 之間。"
  }
}

variable "rate_limit_count" {
  type        = number
  description = "Rate Limiting 的請求數門檻。"
  default     = 100
}

variable "rate_limit_interval_sec" {
  type        = number
  description = "Rate Limiting 的計算區間（秒）。"
  default     = 60
}
