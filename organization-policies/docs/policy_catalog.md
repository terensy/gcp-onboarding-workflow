# GCP Organization Policy 清單

對應 `policies_catalog.yaml` 目前收錄的 33 項政策，整理成中英對照表，方便非 Terraform 讀者（例如客戶簡報、稽核紀錄）查閱。資料來源與版本同 [README.md](../README.md)：CIS Google Cloud Platform Foundation Benchmark v5.0.0，以及 GCP [Organization Policy Constraints 官方文件](https://docs.cloud.google.com/organization-policy/reference/org-policy-constraints)。

**GCP Default / CIS 欄位說明：**

| 標示 | 意義 |
|---|---|
| `GCP Default` | Google 依官方文件屬於自動強制（automatically enforced）的政策 |
| `CIS` | CIS Benchmark 明文建議新增的政策，Google 預設不會自動套用 |
| `Extended` | CIS 條文未直接點名，但方向上強化對應控制項的延伸建議 |

## CIS 建議新增（12 項）

| Service | Policy Name (Constraint ID) | Description (English) | 說明（中文） | GCP Default / CIS |
|---|---|---|---|---|
| IAM | `iam.allowedPolicyMemberDomains` | Restricts IAM policy members to an allow-listed set of Cloud Identity/Workspace customer IDs, blocking personal or external accounts from being granted roles. | 僅允許組織自有 Cloud Identity／Workspace 網域帳號被授予 IAM 角色，避免個人 Gmail 帳號被授權。 | CIS (1.2 · 5.1 · 7.1) |
| IAM | `iam.disableServiceAccountKeyCreation` | Disables creation of user-managed service account keys. | 禁止建立使用者管理的服務帳戶金鑰。 | CIS (1.5) |
| IAM | `iam.disableServiceAccountCreation` | Disables creation of new service accounts entirely. | 完全禁止建立新服務帳戶（選用，適用不需要服務帳戶的資料夾／專案）。 | CIS (1.5 附註) |
| Compute Engine | `compute.skipDefaultNetworkCreation` | Skips auto-creation of the default VPC network and its permissive default firewall rules in new projects. | 新專案不自動建立 default 網路及其寬鬆防火牆規則（SSH／RDP／內部全開）。 | CIS (3.1) |
| Compute Engine | `compute.requireOsLogin` | Requires OS Login for SSH access instead of metadata-based SSH keys. | 強制以 IAM 綁定管理 SSH 存取，取代 metadata SSH 金鑰。 | CIS (4.4) |
| Compute Engine | `compute.vmExternalIpAccess` | Restricts which VM instances may be assigned an external IP address. | 拒絕建立／更新帶有外部 IP 的 VM（或白名單特定資源）。 | CIS (4.9) |
| Compute Engine | `compute.disableSerialPortAccess` | Disables serial port access to VM instances. | 禁止啟用序列埠存取，避免不受 IP 限制的連線管道。 | CIS (4.5) |
| Compute Engine | `compute.requireShieldedVm` | Requires all new VM instances to use Shielded VM (Secure Boot, vTPM, integrity monitoring). | 要求所有新 VM 啟用 Secure Boot／vTPM／完整性監控。 | CIS (4.8) |
| Cloud Storage | `storage.uniformBucketLevelAccess` | Enforces uniform bucket-level access, disabling ACL-based object-level permissions. | 強制以 IAM 取代 ACL 管理 bucket 權限，避免物件層級例外開放。 | CIS (5.2) |
| Cloud SQL | `sql.restrictPublicIp` | Restricts Cloud SQL instances from being configured with a public IP address. | 禁止 Cloud SQL 執行個體設定公開 IP。 | CIS (6.7) |
| Cloud SQL | `sql.restrictAuthorizedNetworks` | Restricts Cloud SQL instances from configuring Authorized Networks. | 禁止 Cloud SQL 設定 Authorized Networks（避免隱性放行任意公開 IP）。 | CIS (6.5) |
| Resource Manager | `gcp.resourceLocations` | Restricts the physical locations where new resources may be created to an allow-listed set of regions. | 限制資源只能建立於核准地區，支援資料落地與集中治理。 | CIS (1.1.4 範例) |

## 延伸建議（2 項）

| Service | Policy Name (Constraint ID) | Description (English) | 說明（中文） | GCP Default / CIS |
|---|---|---|---|---|
| Cloud Storage | `storage.publicAccessPrevention` | Blocks public access to Cloud Storage buckets/objects outright, regardless of IAM or ACL grants. | 直接阻擋 bucket 被公開存取，比僅依賴 Domain Restricted Sharing／IAM 更強一層防線。 | Extended（延伸支援 CIS 5.1） |
| Compute Engine | `compute.vmCanIpForward` | Restricts VM instances from being created/updated with IP forwarding enabled. | 拒絕建立／更新啟用 IP Forwarding 的 VM。新一代 managed constraint，正式命名可能為 `compute.managed.vmCanIpForward`，套用前請核對。 | Extended（延伸支援 CIS 4.6） |

## Google 自動強制 — 已納入 Terraform 管理（5 項）

命名語意明確的布林開關；即便 schema 猜測有誤，`terraform apply` 也只會報錯，不會被靜默套用成錯誤設定，因此已 codify 成 Terraform 資源，每次 apply 都重新確認實際生效狀態。

| Service | Policy Name (Constraint ID) | Description (English) | 說明（中文） | GCP Default / CIS |
|---|---|---|---|---|
| IAM | `iam.disableCrossProjectServiceAccountUsage` | Disallows using a service account outside of the project it belongs to. | 禁止跨專案使用服務帳戶。 | GCP Default |
| IAM | `iam.managed.disableAccessPolicyBinding` | Disallows binding a V3 access policy to a resource. | 禁止將 V3 access policy 綁定至資源。 | GCP Default |
| Cloud Build | `cloudbuild.disableCreateDefaultServiceAccount` | Disables automatic creation of the legacy Cloud Build default service account. | 禁止建立舊版 Cloud Build 服務帳戶。 | GCP Default |
| Compute Engine | `compute.managed.blockPreviewFeatures` | Blocks use of Compute Engine Alpha API preview features. | 封鎖 Compute Alpha API 預覽功能。 | GCP Default |
| Discovery Engine / Gemini Enterprise | `discoveryengine.managed.disableCustomMcpServerConnector` | Disables custom MCP server data connectors for Gemini Enterprise. | 禁止自訂 MCP Server 資料連接器。 | GCP Default |

## Google 自動強制 — 待核對，僅唯讀稽核（14 項）

多為 list 型且需要組織特定值（專案白名單、FQDN、服務名稱…），或語意方向不明確（如「Use X」）。猜錯 schema 可能「成功套用但做錯事」，風險高於單純 apply 失敗，因此 Terraform 不寫入，僅以 `scripts/verify_effective_policies.sh` 唯讀查詢實際生效狀態。

| Service | Policy Name (Constraint ID) | Description (English) | 說明（中文） | GCP Default / CIS |
|---|---|---|---|---|
| IAM | `iam.serviceAccountKeyExposureResponse` | Governs the automatic response action taken when a service account key is detected as exposed. | 服務帳戶金鑰外洩時的自動回應機制；可能是 enum 型態而非單純布林，需先核對 schema。 | GCP Default |
| IAM | `iam.managed.disableServiceAccountApiKeyCreation` | Disables creation of API keys bound to a service account, unless the key's API targets are limited to an allow-listed set of services. | 禁止建立綁定服務帳戶、且 API 範圍未受限的 API 金鑰。 | GCP Default |
| IAM | `iam.allowServiceAccountCredentialLifetimeExtension` | Controls whether extended service account credential lifetimes are permitted. | 限制服務帳戶憑證有效期延長。 | GCP Default |
| Cloud Build | `cloudbuild.useBuildServiceAccount` | Governs default use of the legacy Cloud Build service account for builds. | 限制預設使用舊版 Cloud Build 服務帳戶的行為。 | GCP Default |
| Cloud Build | `cloudbuild.useComputeServiceAccount` | Governs default use of the Compute Engine default service account for builds. | 限制預設使用 Compute Engine 服務帳戶的行為。 | GCP Default |
| Compute Engine | `compute.sharedReservationsOwnerProjects` | Restricts which projects may own/create shared VM reservations. | 限制可建立共用預留資源（reservation）的專案。 | GCP Default |
| GKE | `container.managed.autopilotPrivilegedAdmission` | Requires allow-list-based admission control for privileged workloads on GKE Autopilot. | GKE Autopilot 特權工作負載需經核准清單審核。 | GCP Default |
| Discovery Engine | `discoveryengine.managed.allowedDataSources` | Restricts the data sources that data connectors are allowed to use. | 限制資料連接器可用的資料來源。 | GCP Default |
| Discovery Engine | `discoveryengine.managed.allowedEgressFqdns` | Restricts the egress FQDNs that data connectors may connect out to. | 限制資料連接器對外連線的網域。 | GCP Default |
| Vertex AI | `vertexai.allowedPartnerModelFeatures` | Defines which advanced features of managed partner models may be used on Vertex AI. | 限制 Vertex AI 合作夥伴模型可用的進階功能。 | GCP Default |
| Resource Manager | `resourcemanager.allowedExportDestinations` | Restricts the allowed destinations for exporting resources/data out of the organization. | 限制專案／資料夾可匯出的目的地。 | GCP Default |
| Resource Manager | `resourcemanager.allowedImportSources` | Restricts the allowed sources for importing resources/data into the organization. | 限制可匯入的來源。 | GCP Default |
| Resource Manager | `resourcemanager.allowEnabledServicesForExport` | Controls which enabled services' data may be exported. | 控制哪些已啟用服務可被匯出。 | GCP Default |
| Marketplace | `commerceorggovernance.marketplaceServices` | Restricts which Marketplace services may be accessed or procured. | 限制可用的 Marketplace 服務類型。 | GCP Default |

---

資料來源：[Organization Policy Constraints — Automatically enforced](https://docs.cloud.google.com/organization-policy/reference/org-policy-constraints#automatically_enforced_constraints) ・ [Available constraints](https://docs.cloud.google.com/organization-policy/reference/org-policy-constraints#available_constraints) ・ CIS Google Cloud Platform Foundation Benchmark v5.0.0。正式導入前請以 `gcloud org-policies list --organization=ORG_ID` 或 `scripts/verify_effective_policies.sh` 核對貴組織實際狀態。
