---
title: 決定 User 來源並建立群組
description: 決定 GCP 的 User account 要源自既有 Identity Provider 還是 Cloud Identity，並規劃最小必要的管理群組。
keywords: [Cloud Identity, IdP, SSO, 群組規劃, IAM 群組]
sidebar_position: 2
---

# 1.2 決定 User 來源 & 建立群組與人員

## User 來源

對於很多公司來說，已經有 Identity Provider（IdP）系統，而 Cloud Identity 也是一種 IdP。所以在讓內部人員使用 GCP 前要確認 User account 是要源自於既有的 IdP 還是直接從 Cloud Identity 中建立 User account。

- 如果是直接用 Cloud Identity 建立 User account，那就直接在 Cloud Identity console 建立群組及使用者。
- 如果是要用既有的 IdP，那就根據 Google 官方及既有的 IdP 官方說明文件進行同步跟整合授權流程。

:::tip
[Entra ID 佈建使用者/群組至 Google Cloud Identity 並設定 SSO 部署與維護 SOP](https://github.com/terensy/entraid-cloudidentity-provisioning-sso-sop.git)
:::

## 群組規劃

通常不管在地端環境或是雲端環境我們都習慣用群組的方式管理權限，因為可以有效率且有邏輯的管理每一個使用者的角色跟權限。因此在決定好使用者來源後就要規劃群組，可以根據 [Google 官方提供的群組規劃範例](https://docs.cloud.google.com/architecture/blueprints/security-foundations/authentication-authorization?hl=zh-tw#groups_for_access_control) 或是目前其他系統的群組劃分邏輯進行。

在細部規劃群組架構之前，至少要先建立以下幾個**最小必要的管理群組**，因為後續章節會直接在 GCP IAM 層級把角色權限指派給它們：

| 群組（命名範例） | 用途 | 之後在 GCP IAM 常對應的角色 |
| --- | --- | --- |
| gcp-organization-admins@ | 管理 GCP Organization 層級設定、Folder/Project 階層 | Organization Administrator |
| gcp-billing-admins@ | 管理 Billing 帳戶、預算與成本控管 | Billing Account Administrator |
| gcp-network-admins@ | 管理共用網路（Shared VPC）、防火牆、混合連線 | Network Admin、Compute Network Admin |
| gcp-security-admins@ | 管理 Organization Policy、IAM 稽核、Security Command Center | Organization Policy Administrator、Security Admin |
| gcp-logging-admins@ | 管理集中式 Log sink、稽核紀錄與監控告警 | Logs Configuration Writer、Monitoring Admin |

上述群組建立後先只加入負責初始化的少數人員（例如目前的超級管理員或 IT 負責人），等 [IAM 角色指派](/organization-setup/iam-bindings) 完成後，再依實際負責人調整成員；建議之後把超級管理員從日常使用中移除，只保留在 [Break-glass 緊急存取帳號](/cloud-identity/verify-domain) 的管理範圍內，降低最高權限帳號的日常曝險。

:::info
不管是 GCP、AWS、Azure 或是其他公有雲都是先知道其基礎知識，再回顧公司內的組織結構或是系統管理層級才可以有效規劃群組。請記住一句話【沒有人比你更了解你的公司】，所以請不要一開始就找合作公司替你處理使用者及群組規劃，應該先自行規劃一版再尋求 Best Practice 建議。
:::

:::info
在 Cloud Identity 中建立的 User account 或是群組，雖然可以設定權限，但是那是控制 Cloud Identity 這個 IdP 的權限跟其他 Google 服務的使用權限，不是 GCP 的。GCP 權限是要在 GCP IAM console 中設定。
:::
