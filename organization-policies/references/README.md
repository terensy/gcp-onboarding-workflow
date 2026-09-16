# 原始參考資料

這裡放的是**原始來源文件**，不是給 Terraform 或腳本讀取的資料：

- `CIS_Google_Cloud_Platform_Foundation_Benchmark_v5.0.0.pdf` — CIS Benchmark 官方全文，作為條文比對的第一手依據。
- `gcp_org_policy_catalog.csv` — 從 PDF 整理出來的 org policy 條文草稿（早期版本）。

**目前正式維護、隨 Terraform module 一起更新的版本在**：

- [`../policies_catalog.yaml`](../policies_catalog.yaml) — Terraform 的唯一資料來源
- [`../docs/policy_catalog.md`](../docs/policy_catalog.md) — 中英對照、可讀版本
- [`../docs/methodology.md`](../docs/methodology.md) — 如何根據公司內部需求調整這份清單

這兩份原始檔留存是為了日後 CIS Benchmark 出新版時，方便重新比對差異；一般使用情境請直接看上面三份文件，不需要回頭讀 PDF/CSV。
