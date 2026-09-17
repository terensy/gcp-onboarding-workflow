terraform {
  required_version = ">= 1.3"

  required_providers {
    google = {
      source = "hashicorp/google"
      # google_model_armor_template 是 2025 年之後才加入的新資源，確切最低可用版本
      # 請以 https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/model_armor_template
      # 為準；terraform init 若回報版本不符，調高這個下限。
      version = ">= 6.30.0"
    }
  }
}
