# CMEK 範例：集中的 Key Ring/Key，搭配 organization-policies/ 的
# constraints/gcp.restrictNonCmekServices + constraints/gcp.restrictCmekCryptoKeyProjects
# 強制特定服務只能用這個 Project 底下的金鑰。

resource "google_kms_key_ring" "this" {
  project  = var.project_id
  name     = var.key_ring_name
  location = var.location
}

resource "google_kms_crypto_key" "this" {
  name            = var.key_name
  key_ring        = google_kms_key_ring.this.id
  rotation_period = var.rotation_period
  purpose         = "ENCRYPT_DECRYPT"

  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = var.protection_level
  }

  # KMS Key 誤刪等於資料永久遺失，刻意用 prevent_destroy 擋掉意外的
  # terraform destroy / 資源改名導致的 replace。
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key_iam_member" "cmek_user" {
  crypto_key_id = google_kms_crypto_key.this.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = var.cmek_user_member
}

output "crypto_key_id" {
  value = google_kms_crypto_key.this.id
}
