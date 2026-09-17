variable "project_id" {
  type        = string
  description = "Model Armor Template 與 Sensitive Data Protection Template 要建立在哪個 Project。"
}

variable "location" {
  type        = string
  description = <<-EOT
    Model Armor Template 與 DLP Template 共用同一個地區。Model Armor 目前僅部分
    Region 支援，套用前請以官方文件核對可用性：
    https://cloud.google.com/security/products/model-armor
  EOT
  default     = "us-central1"
}

variable "template_id_prefix" {
  type        = string
  description = "產生的資源命名前綴，例如 \"ai-baseline\" 會產生 ai-baseline-model-armor 等資源 ID。"
  default     = "ai-baseline"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.template_id_prefix))
    error_message = "template_id_prefix 只能包含英數字與連字號（Model Armor template_id 命名限制）。"
  }
}

variable "pii_info_types" {
  type        = list(string)
  description = <<-EOT
    Sensitive Data Protection 要偵測的 PII infoType 清單，需為 Google 官方
    built-in infoType 名稱（完整清單見
    https://docs.cloud.google.com/sensitive-data-protection/docs/infotypes-reference）。
    對應 ai-onboarding/README.md 的 Baseline 預設值草案：常見 PII 的保守起點，
    客戶所在地若有額外法規要求（例如需要偵測特定國家的身分證號），透過
    enable_custom_id_pattern 另外加規則，不要塞進這個清單猜測不存在的 infoType 名稱。
  EOT
  default = [
    "EMAIL_ADDRESS",
    "PHONE_NUMBER",
    "CREDIT_CARD_NUMBER",
    "PERSON_NAME",
    "STREET_ADDRESS",
  ]
}

variable "enable_custom_id_pattern" {
  type        = bool
  description = <<-EOT
    是否額外偵測 custom_id_pattern 定義的自訂身分證號格式。Google 官方 built-in
    infoType 清單裡沒有可確認的「台灣身分證字號」項目（未經官方文件逐條核對前，
    不寫死猜測的 infoType 名稱），因此改用 custom_info_types + regex 做格式比對
    （只驗證格式，不是官方檢查碼演算法），套用前務必跟客戶法遵確認是否符合實際需求。
  EOT
  default     = true
}

variable "custom_id_pattern" {
  type        = string
  description = <<-EOT
    custom_info_types 用的 regex pattern。預設值是台灣身分證字號的格式（1 碼英文
    字母 + 9 碼數字），僅做格式比對、未實作官方檢查碼驗證邏輯，套用前請自行驗證
    是否符合實際需求或替換成客戶所在地的格式。
  EOT
  default     = "\\b[A-Z][12]\\d{8}\\b"
}

variable "prompt_injection_confidence" {
  type        = string
  description = <<-EOT
    Model Armor Prompt Injection / Jailbreak 偵測的信心度門檻。對應
    ai-onboarding/README.md 的 Baseline 預設值：先設 MEDIUM_AND_ABOVE，
    避免正常業務對話被誤擋（寧可先漏放低信心度案例，也不要一開始就因為
    false positive 被客戶關掉整個防護）。
  EOT
  default     = "MEDIUM_AND_ABOVE"

  validation {
    condition     = contains(["LOW_AND_ABOVE", "MEDIUM_AND_ABOVE", "HIGH"], var.prompt_injection_confidence)
    error_message = "prompt_injection_confidence 必須是 LOW_AND_ABOVE / MEDIUM_AND_ABOVE / HIGH 其中之一。"
  }
}

variable "enable_malicious_uri_filter" {
  type        = bool
  description = "是否開啟惡意 URL 偵測。對應 Baseline 預設值：預設開啟。"
  default     = true
}

variable "enforcement_type" {
  type        = string
  description = <<-EOT
    Model Armor 偵測到違規時的處理方式：
      INSPECT_ONLY       只記錄 Finding，不擋流量（dry-run）
      INSPECT_AND_BLOCK  直接擋下違規的 prompt/response

    預設 INSPECT_ONLY——呼應本專案 VPC-SC／Binary Authorization 一貫的
    「先 dry-run 觀察一輪，確認不會誤擋正常業務流程，再 enforce」慣例，
    不要一套用就直接開始擋線上流量。觀察期沒有固定天數，取決於業務的
    使用模式複雜度，確認 Finding 都是預期內的違規之後，再由客戶決定
    改成 INSPECT_AND_BLOCK。
  EOT
  default     = "INSPECT_ONLY"

  validation {
    condition     = contains(["INSPECT_ONLY", "INSPECT_AND_BLOCK"], var.enforcement_type)
    error_message = "enforcement_type 必須是 INSPECT_ONLY 或 INSPECT_AND_BLOCK。"
  }
}

variable "labels" {
  type        = map(string)
  description = "掛在 Model Armor Template 上的 Labels，比照主專案 8.1 節的成本歸屬慣例。"
  default     = {}
}
