terraform {
  required_version = ">= 1.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.60.0"
    }
  }
}

provider "google" {
  # 建議透過 GOOGLE_APPLICATION_CREDENTIALS 環境變數或 gcloud auth
  # application-default login 提供憑證，不在此檔案內寫入金鑰路徑。
  #
  # 這是唯一還需要用人工憑證 apply 的地方（雞生蛋蛋生雞：WIF 本身要先被
  # 建出來，CI/CD 才有辦法用 WIF）。bootstrap 完成之後，其餘所有子專案都
  # 應該透過這裡建立的 WIF 走 CI/CD apply，不要再用個人憑證。
}
