terraform {
  required_version = ">= 1.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.30.0"
    }
  }
}

provider "google" {
  # 建議透過 GOOGLE_APPLICATION_CREDENTIALS 環境變數或 gcloud auth
  # application-default login 提供憑證，不在此檔案內寫入金鑰路徑。
}
