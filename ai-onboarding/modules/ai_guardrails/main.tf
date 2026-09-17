# -----------------------------------------------------------------------------
# Sensitive Data Protection（PII）—— Inspect + De-identify Template
#
# 只負責「偵測＋遮蔽」，不是整段擋掉：對應 ai-onboarding/README.md 的
# Baseline 預設值——偵測到 PII 時預設動作是去識別化（character mask），
# 阻擋行為交給下面 Model Armor Template 的 enforcement_type 統一控制。
# -----------------------------------------------------------------------------

resource "google_data_loss_prevention_inspect_template" "pii_baseline" {
  parent       = "projects/${var.project_id}/locations/${var.location}"
  display_name = "${var.template_id_prefix}-pii-inspect"
  description  = "AI 基礎設施導入 baseline PII 偵測範本，供 Model Armor SDP 整合使用。"

  inspect_config {
    dynamic "info_types" {
      for_each = var.pii_info_types
      content {
        name = info_types.value
      }
    }

    dynamic "custom_info_types" {
      for_each = var.enable_custom_id_pattern ? [1] : []
      content {
        info_type {
          name = "CUSTOM_ID_FORMAT"
        }
        likelihood = "POSSIBLE"
        regex {
          pattern = var.custom_id_pattern
        }
      }
    }

    min_likelihood = "POSSIBLE"
  }
}

resource "google_data_loss_prevention_deidentify_template" "pii_baseline" {
  parent       = "projects/${var.project_id}/locations/${var.location}"
  display_name = "${var.template_id_prefix}-pii-deidentify"
  description  = "AI 基礎設施導入 baseline PII 遮蔽範本——預設動作是去識別化，不是整段擋掉。"

  deidentify_config {
    info_type_transformations {
      dynamic "transformations" {
        for_each = var.pii_info_types
        content {
          info_types {
            name = transformations.value
          }
          primitive_transformation {
            # 不設定 number_to_mask：DLP 預設會遮蔽整個 finding，而不是只遮
            # 固定幾個字元，對應 Baseline「偵測到 → 去識別化」的完整遮蔽語意。
            character_mask_config {
              masking_character = "*"
            }
          }
        }
      }

      dynamic "transformations" {
        for_each = var.enable_custom_id_pattern ? [1] : []
        content {
          info_types {
            name = "CUSTOM_ID_FORMAT"
          }
          primitive_transformation {
            character_mask_config {
              masking_character = "*"
            }
          }
        }
      }
    }
  }
}

# -----------------------------------------------------------------------------
# Model Armor Template —— 語義層防護（Prompt Injection/Jailbreak、惡意 URL、
# 整合上面的 SDP Template 做 PII 偵測/遮蔽）
# -----------------------------------------------------------------------------

resource "google_model_armor_template" "baseline" {
  project     = var.project_id
  location    = var.location
  template_id = "${var.template_id_prefix}-model-armor"
  labels      = var.labels

  filter_config {
    pi_and_jailbreak_filter_settings {
      filter_enforcement = "ENABLED"
      confidence_level   = var.prompt_injection_confidence
    }

    dynamic "malicious_uri_filter_settings" {
      for_each = var.enable_malicious_uri_filter ? [1] : []
      content {
        filter_enforcement = "ENABLED"
      }
    }

    sdp_settings {
      advanced_config {
        inspect_template    = google_data_loss_prevention_inspect_template.pii_baseline.name
        deidentify_template = google_data_loss_prevention_deidentify_template.pii_baseline.name
      }
    }
  }

  template_metadata {
    log_template_operations = true
    log_sanitize_operations = true
    enforcement_type        = var.enforcement_type
  }
}
