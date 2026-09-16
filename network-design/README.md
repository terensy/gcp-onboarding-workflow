# GCP Network Design Terraform Modules

對應最外層 [README.md](../README.md#3-gcp-網路設計) 第 3 章。提供兩個獨立的 Terraform module：

- **`modules/shared_vpc`** — Shared VPC（Host Project + Service Project + 子網路 + Cloud NAT）。
- **`modules/hierarchical_firewall`** — 掛在 Organization/Folder 層級的階層式防火牆政策，由 `firewall_baseline_catalog.yaml` 驅動（沿用 [organization-policies/](../organization-policies/) 的「資料驅動」設計）。

兩個 module 互相獨立，可以只用其中一個，也可以像 `examples/root` 一樣一起用。

## 目錄結構

```
.
├── firewall_baseline_catalog.yaml     # 階層式防火牆的基準規則清單
├── modules/
│   ├── shared_vpc/                    # Host Project、VPC、子網路、Cloud NAT
│   └── hierarchical_firewall/         # 讀 catalog 產生階層式防火牆政策
├── examples/root/                     # 兩個 module 一起用的完整範例
└── docs/
    └── methodology.md                 # 網路拓樸怎麼選、CIDR 怎麼規劃
```

## 快速開始

```bash
cd examples/root
cp terraform.tfvars.example terraform.tfvars
# 編輯 terraform.tfvars：填入 org_id、host_project_id、service_project_ids、subnets

terraform init
terraform plan
terraform apply
```

套用帳號至少需要：Host Project 與 Service Project 上的 `roles/compute.xpnAdmin`（或在 Organization 層級授予，見 [iam-bindings/](../iam-bindings/)）、Organization 層級的 `roles/compute.securityAdmin` 或等效權限（建立階層式防火牆政策）。

> [!NOTE]
> 這兩個 module 只處理**網路骨架**（VPC、子網路、NAT、防火牆基準線）。VPC Service Controls、DNS Peering/Forwarding 的實際設定、Private Service Connect 端點目前不在這裡，前者見 [security-products/docs/vpc-service-controls.md](../security-products/docs/vpc-service-controls.md)，後兩者依各組織的 DNS/PSC 需求差異太大，暫時以文件（最外層 README.md 3.3 節）呈現，沒有做成通用 module。

## `shared_vpc` module 在做什麼

1. 把 `host_project_id` 指定的專案設為 Shared VPC Host Project。
2. 把 `service_project_ids` 列出的專案逐一附加進去。
3. 建立一個 `auto_create_subnetworks = false` 的自訂 VPC，依 `var.subnets`（`region` / `ip_cidr_range` / 選填的 GKE 次要範圍）逐一建立子網路，預設開啟 Private Google Access 與 VPC Flow Logs。
4. 若 `enable_cloud_nat = true`（預設），對每個用到的 Region 各建一組 Cloud Router + Cloud NAT，讓沒有外部 IP 的 VM 仍能出網——這是刻意跟 [organization-policies/](../organization-policies/) 的 `compute.vmExternalIpAccess` 政策搭配使用的，兩者要一起套用，只套用其中一個會讓 VM 連套件更新都下載不了。

## `hierarchical_firewall` module 在做什麼

讀 `firewall_baseline_catalog.yaml`，用 `for_each` 對每一筆規則產生 `google_compute_firewall_policy_rule`。這份 catalog 預設收錄 4 條 Google 官方 Security Foundations Blueprint 建議的基準規則：

| 規則 | 用途 |
|---|---|
| `allow-iap-tcp-forwarding-ingress` | 放行 IAP TCP forwarding range（`35.235.240.0/20`），SSH/RDP 走 IAM 而不是暴露的 Port |
| `allow-lb-health-check-ingress` | 放行 Load Balancer 健康檢查來源 |
| `allow-internal-rfc1918-ingress` | 放行內部 RFC 1918 流量 |
| `default-deny-ingress` | 最低優先權的預設全擋——micro-segmentation 的最後一道防線 |

`priority` 數字越小評估越優先（GCP 防火牆是 first-match-wins）；catalog 開頭的註解說明本專案採用的優先權區段慣例。個別 VPC/Workload 才需要的規則，不要塞進這份全公司共用的 catalog，透過 `var.extra_rules` 傳入，或另外用 Network Firewall Policy 處理。

## 已知限制

- **這裡的階層式防火牆政策只處理 INGRESS 規則**（IAP/健康檢查/RFC1918/預設擋）。EGRESS 規則（例如限制對外連線目的地）目前要透過 `var.extra_rules` 自行加入，`direction: EGRESS` 的規則會自動改用 `dest_ip_ranges`。
- **`shared_vpc` module 假設是「選項 1：每個環境一個 Shared VPC」**（見 [docs/methodology.md](docs/methodology.md)）。如果貴組織評估後選擇 Hub-and-Spoke（選項 2/3）或 Private Service Connect 生產者/消費者模式（選項 4），這個 module 的 Host/Service Project 架構不適用，需要另外設計。
- **CIDR 範圍需要人工先規劃好**，module 本身不會幫你算子網路要怎麼切，不要子網路重疊了才發現——規劃方法見 [docs/methodology.md](docs/methodology.md)。
