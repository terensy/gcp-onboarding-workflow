# 方法論：VPC Service Controls 從盤點到 Enforce

[最外層 README.md 5.2 節](../../README.md#52-vpc-service-controls-vpc-sc)說明了 VPC-SC 是什麼、為什麼需要它。這份文件補完「實際要怎麼導入」——這是全部治理章節裡風險最高的一項，設錯不是 `apply` 報錯，是正式環境的資料管線直接斷線，所以特別獨立成一份文件，值得花時間讀完再動手。

這個子專案沒有附上「一鍵套用」的 Terraform module——**故意的**。Perimeter 該圍哪些 Project、Access Level 該放哪些 IP/身分，每個組織的答案都不一樣，用猜的寫成通用 module 反而會鼓勵大家跳過盤點直接套用，那正是這份文件想避免的事。

<br>

## 核心概念回顧

- **Service Perimeter**：把一群 Project 圍起來，預設全擋跨越邊界的存取。一個 Project 只能屬於一個 Perimeter。
- **Access Level**：用 IP 範圍／裝置政策／身分白名單，定義「誰可以從邊界外進來」，在 Access Context Manager 設定。
- **Ingress / Egress Rule**：比 Perimeter Bridge 更細緻的例外機制。[Google 官方明講](https://cloud.google.com/vpc-service-controls/docs/architect-perimeters)不建議用多個 Bridge 或 DMZ Perimeter 這種複雜設計——能用 Ingress/Egress Rule 解決就不要疊 Bridge，過度分割的 Perimeter 只會讓維運複雜度線性上升。

VPC-SC 管的是「資料能不能被搬到邊界之外」，不是「誰能存取這個資源」（那是 IAM 的工作）。兩者要一起用，VPC-SC 不是拿來取代 IAM 的。

<br>

## 官方建議的導入流程

[Google 官方的企業導入指南](https://cloud.google.com/vpc-service-controls/docs/enable)把整個流程拆成 6 個階段，這裡不是可以跳過中間步驟直接跳到最後的清單，每一步都是為了不要讓正式環境當白老鼠：

### 1. 協調與溝通

通常由網路安全或雲端平台團隊主導，需要一個人專責追蹤跨團隊的會議與行動項目——VPC-SC 的邊界會影響到每一個有資料進出的應用團隊，不是平台團隊自己關起門來能決定的事。

### 2. 盤點所有合法的存取模式

這是整個流程裡最花時間、也最不能省略的一步。要逐一記錄三類存取模式：

- **資料存取模式**：外部服務讀寫 Perimeter 內資料的管道（例如 BI 工具連 BigQuery、備份系統讀 GCS）。
- **資源存取模式**：Console、第三方工具、內部 API 呼叫。
- **端點存取模式**：受管理裝置、地端連線。

每一項都要記下「觸發者是誰」「觸發條件」「是不是合法」。Google 官方提供[現成的盤點範本 PDF](https://cloud.google.com/static/solutions/vpc-service-controls-enterprise-best-practices-use-cases-template.pdf)，直接照著填，不用自己重新設計格式。

> [!WARNING]
> 這一步最容易漏掉的幾類存取，Google 官方逐一點名過：
> - **CI/CD 與自動化工具**（Terraform、Jenkins、Azure DevOps）——這些通常跑在 Perimeter 外，但管理著 Perimeter 內的資源。
> - **設定管理工具**（Ansible、Chef、Puppet）。
> - **地端經 VPN/Interconnect 連進來的流量**——連線會被算在「連線所在的那個 VPC 專案」，Shared VPC 情境下這代表 **Host Project 也要在 Perimeter 內**，漏了 Host Project 會直接跳 `NETWORK_NOT_IN_SAME_SERVICE_PERIMETER`。
> - **Cloud Logging 匯出用的 Google 代管服務帳戶**（`p<num>@gcp-sa-logging.iam.gserviceaccount.com`），這個帳戶需要自己的 Egress Rule。
> - **Cloud Build**：Worker 預設跑在 Google 代管的 Tenant Project，即使你的專案在 Perimeter 內，Cloud Build API 呼叫預設還是會被擋，需要額外的 Ingress Rule。

### 3. 訪談確認

跟每個應用團隊確認：這個 workload 的優先順序、盤點清單有沒有漏掉的存取模式、時程上有沒有跟 VPC-SC 導入衝突的重大變更（例如同時在遷移資料庫）。

### 4. 準備 Dry-run

- 選出這一輪要納入的 Project。
- 建立 Dry-run Perimeter，把該加的服務全部加進保護清單。
- 設定 Log Sink 把 Dry-run 違規紀錄匯到 BigQuery。
- 把盤點階段確認過的合法存取模式，先預先加進 Access Level／Ingress Rule。
- 確認沒有 VPC 路由繞過 `restricted.googleapis.com`，且 DNS 有把 `*.googleapis.com` 導向 `restricted.googleapis.com`。

### 5. 執行使用情境

讓應用團隊在 Dry-run 期間，照平常的方式把該跑的流程都跑一遍——排程任務、CI/CD、月底批次工作都要涵蓋到，只測「平常會用到的功能」很容易漏掉低頻但關鍵的流程（例如季報表、年度歸檔）。

### 6. 分析違規紀錄，才真的 Enforce

查詢 BigQuery 裡匯出的 `cloudaudit_googleapis_com_policy` 表（`dryRun = "true"`），對每一筆違規判斷：這個存取應不應該被允許？該加白名單就加，不該的就代表原本的設計本來就有漏洞，VPC-SC 幫忙抓出來了。全部審過、確認沒有非預期的阻擋之後，才執行：

```bash
gcloud access-context-manager perimeters dry-run enforce PERIMETER_NAME
```

> [!CAUTION]
> Enforce 是**逐一 Perimeter 執行**，不是全部一次到位。Google 官方建議優先保護真正重要的 workload，其餘風險較低的 Project 晚一點再排進來——不要為了「一次做完」把還沒驗證過的 Project 一起 Enforce，那等於把還沒走完 Dry-run 流程的東西直接跳過驗證上線。

<br>

## Google 自家 Blueprint 的預設姿態

[Security Foundations Blueprint](https://cloud.google.com/architecture/security-foundations/operation-best-practices) 預設也**只部署 Dry-run 模式**，enforce 與否留給每個組織自己評估——連 Google 自己的參考架構都不預設幫你打開 Enforce，這個決定本來就該是「看完自己的違規紀錄之後」才做，不是「上線當天」的預設值。Blueprint 也建議規劃 **Breakglass 存取**：萬一 Perimeter 真的擋到自動化管線，要有一個緊急修改 Perimeter 的管道，而不是整條 Pipeline 卡死等變更審核。

<br>

## 快速檢查清單

- [ ] 盤點清單是否涵蓋 CI/CD、設定管理工具、地端連線（含 Shared VPC Host Project）、Logging 匯出？
- [ ] 是否先跑過完整的 Dry-run 週期（至少涵蓋一次月底/季度批次工作），而不是只測了幾天的日常流量？
- [ ] 違規紀錄是否每一筆都有人工判斷過，而不是看到數量太多就整批加白名單放行？
- [ ] Enforce 是否按 workload 優先順序分批執行，而不是一次全部上線？
- [ ] 是否規劃了 Breakglass 存取，萬一 Enforce 後真的擋到未預期的流量，有辦法緊急處理？
