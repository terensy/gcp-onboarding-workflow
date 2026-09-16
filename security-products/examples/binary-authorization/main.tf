# Binary Authorization 範例：要求 GKE 叢集只接受帶有「通過核准的 CI/CD
# Pipeline 建置」簽章證明的容器映像檔。enforcement_mode 預設是 Dry-run
# （只記錄不擋），跟 VPC-SC 一樣建議分階段導入，見最外層 README.md 5.6 節。

resource "google_container_analysis_note" "this" {
  project = var.project_id
  name    = var.note_name

  attestation_authority {
    hint {
      human_readable_name = var.attestor_display_name
    }
  }
}

resource "google_binary_authorization_attestor" "this" {
  project = var.project_id
  name    = var.attestor_name

  attestation_authority_note {
    note_reference = google_container_analysis_note.this.name

    public_keys {
      id                           = var.pgp_public_key_id
      ascii_armored_pgp_public_key = var.pgp_public_key
    }
  }
}

resource "google_binary_authorization_policy" "this" {
  project = var.project_id

  default_admission_rule {
    evaluation_mode         = "REQUIRE_ATTESTATION"
    enforcement_mode        = var.enforcement_mode
    require_attestations_by = [google_binary_authorization_attestor.this.name]
  }

  global_policy_evaluation_mode = "ENABLE"
}

output "attestor_id" {
  value = google_binary_authorization_attestor.this.id
}
