# GCP Network Design Terraform Modules

對應最外層 [README.md](../README.md#3-gcp-網路設計) 第 3 章。提供三個獨立的 Terraform module：

- **`modules/shared_vpc`** — Shared VPC（Host Project + Service Project + 子網路 + Cloud NAT）。
- **`modules/hierarchical_firewall`** — 掛在 Organization/Folder 層級的階層式防火牆政策，由 `firewall_baseline_catalog.yaml` 驅動（沿用 [organization-policies/](../organization-policies/) 的「資料驅動」設計）。
- **`modules/cloud_vpn`** — 對應 [README.md 3.2 節「混合雲連線」](../README.md#32-混合雲連線)的 Cloud VPN（HA VPN），**選用**（是否建立由 `examples/root` 的 `enable_vpn` 開關決定，預設關閉）。

三個 module 互相獨立，可以只用其中一個或兩個，也可以像 `examples/root` 一樣一起用。

> [!NOTE]
> `shared_vpc`、`hierarchical_firewall`、`cloud_vpn` 這三個 module 也被 [sme-quickstart/](../sme-quickstart/) 直接引用，中小企業版本沒有另外簡化網路這塊的邏輯。

## 目錄結構

```
.
├── firewall_baseline_catalog.yaml     # 階層式防火牆的基準規則清單
├── modules/
│   ├── shared_vpc/                    # Host Project、VPC、子網路、Cloud NAT
│   ├── hierarchical_firewall/         # 讀 catalog 產生階層式防火牆政策
│   └── cloud_vpn/                     # HA VPN Gateway + Cloud Router(BGP) + Tunnel，選用
├── examples/root/                     # 三個 module 一起用的完整範例，VPN 由 enable_vpn 開關控制
└── docs/
    └── methodology.md                 # 網路拓樸怎麼選、CIDR 怎麼規劃
```

## 快速開始

```bash
cd examples/root
cp terraform.tfvars.example terraform.tfvars
# 編輯 terraform.tfvars：填入 org_id、host_project_id、service_project_ids、subnets
# 沒有混合雲需求就不用理會 vpn_* 系列變數，enable_vpn 預設 false

terraform init
terraform plan
terraform apply
```

套用帳號至少需要：Host Project 與 Service Project 上的 `roles/compute.xpnAdmin`（或在 Organization 層級授予，見 [iam-bindings/](../iam-bindings/)）、Organization 層級的 `roles/compute.securityAdmin` 或等效權限（建立階層式防火牆政策）；`enable_vpn = true` 時額外需要 Host Project 上的 `roles/compute.networkAdmin`（建立 HA VPN Gateway/Cloud Router/Tunnel）。

> [!NOTE]
> 這三個 module 只處理**網路骨架**（VPC、子網路、NAT、防火牆基準線、選用的 HA VPN）。VPC Service Controls、DNS Peering/Forwarding 的實際設定、Private Service Connect 端點目前不在這裡，前者見 [security-products/docs/vpc-service-controls.md](../security-products/docs/vpc-service-controls.md)，後兩者依各組織的 DNS/PSC 需求差異太大，暫時以文件（最外層 README.md 3.3 節）呈現，沒有做成通用 module。

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

## `cloud_vpn` module 在做什麼（選用）

對應最外層 README.md 3.2 節，建立 [HA VPN](https://docs.cloud.google.com/network-connectivity/docs/vpn/concepts/overview#ha-vpn-diagram) 連回地端網路：

1. **HA VPN Gateway**：2 個 interface，各自對外有一個公開 IP。
2. **專用的 Cloud Router**（跟 `shared_vpc` 給 Cloud NAT 用的 Router 分開），跑 BGP 動態路由。
3. **External VPN Gateway**：代表地端設備，依 `peer_external_ips` 填 1 或 2 個 IP，自動決定 `redundancy_type`。
4. **2 條 VPN Tunnel + BGP session**（`var.tunnels`）：一條接 interface 0，一條接 interface 1，才能達到 HA VPN 官方保證的 99.99% SLA；只接 1 條的話 SLA 降為 99.9%。

> [!IMPORTANT]
> **是否建立由 `examples/root` 的 `enable_vpn` 變數控制，預設 `false`。** 沒有混合雲需求（見最外層 README.md [3.1](../README.md#31-網路架構設計)/[3.2](../README.md#32-混合雲連線) 節的判斷原則）就不需要打開，`terraform plan` 在 `enable_vpn = false` 時完全不會產生 VPN 相關資源。要打開時，把 `enable_vpn = true` 跟 `vpn_*` 系列變數填進 `terraform.tfvars`，範例見 [terraform.tfvars.example](examples/root/terraform.tfvars.example)。

> [!WARNING]
> IKE 共用金鑰**不要**跟其他變數一起放進 `terraform.tfvars`：`var.vpn_tunnels` 只放非敏感的介面/BGP 設定，金鑰要透過另一個變數 `var.vpn_tunnel_shared_secrets`（`sensitive = true`）帶入，建議用 `TF_VAR_vpn_tunnel_shared_secrets` 環境變數或接 CI/CD 的 Secret 管理，不要提交進版控。這是刻意把「敏感值」跟「拿去當 `for_each` key 的值」分開——Terraform 不允許用 sensitive 值當 `for_each`，兩個值混在同一個變數會直接 `terraform validate` 失敗。

> [!NOTE]
> 這個 module 只處理 **Google Cloud 這一端**的 HA VPN 設定。地端設備（防火牆/路由器）對應的 BGP、IKE 設定要由地端網路團隊自行設定，雙方的 ASN、BGP link-local IP、共用金鑰、介面對應關係要先兩邊對好，其中一邊填錯 tunnel 就是「起得來但一直是 `WAITING_FOR_FULL_CONFIG` 或 `NO_INCOMING_PACKETS`」，`terraform apply` 本身不會報錯，要另外用 `tunnel_status` output 或 console/`gcloud compute vpn-tunnels describe` 確認實際連線狀態。
>
> Dedicated/Partner/Cross-Cloud Interconnect（見最外層 README.md 3.2 節比較表）需要走實體線路申請流程，不是單靠 Terraform 就能生效，這裡沒有對應 module；先評估清楚 3.2 節的判斷原則，確定要用 Cloud VPN 才套用這個 module。

## 已知限制

- **這裡的階層式防火牆政策只處理 INGRESS 規則**（IAP/健康檢查/RFC1918/預設擋）。EGRESS 規則（例如限制對外連線目的地）目前要透過 `var.extra_rules` 自行加入，`direction: EGRESS` 的規則會自動改用 `dest_ip_ranges`。
- **`shared_vpc` module 假設是「選項 1：每個環境一個 Shared VPC」**（見 [docs/methodology.md](docs/methodology.md)）。如果貴組織評估後選擇 Hub-and-Spoke（選項 2/3）或 Private Service Connect 生產者/消費者模式（選項 4），這個 module 的 Host/Service Project 架構不適用，需要另外設計。
- **CIDR 範圍需要人工先規劃好**，module 本身不會幫你算子網路要怎麼切，不要子網路重疊了才發現——規劃方法見 [docs/methodology.md](docs/methodology.md)。
- **`cloud_vpn` module 只支援 BGP 動態路由**（每條 tunnel 各自的 Cloud Router interface + peer），不支援純靜態路由的 HA VPN 設定；地端設備需要能跑 BGP。只有單一地端設備、想先簡化測試連線時，`peer_external_ips` 可以只填 1 個 IP（`SINGLE_IP_INTERNALLY_REDUNDANT`），但正式環境建議填 2 個 IP 搭配 2 條 tunnel，才有 99.99% SLA。
