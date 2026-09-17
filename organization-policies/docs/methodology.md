# 方法論：如何依公司內部需求調整 GCP Organization Policies

[README.md](../README.md) 和 [policy_catalog.md](policy_catalog.md) 說明的是「這個 repo 目前收錄了哪些政策、Terraform 怎麼運作」。

這份文件回答的是更前面一步的問題：**貴組織該怎麼決定，`policies_catalog.yaml` 裡每一條政策要不要開、開在哪個層級、值該填什麼？** CIS Benchmark 只是一個通用起點，不是每間公司都要照單全收——沒有人比你更了解你的公司，Org Policy 的取捨也是同樣道理：先照公司自己的風險與業務盤點一輪，再參考外部的 Best Practice 補強，而不是反過來照單全收。

<br>

## 核心原則

1. **政策是護欄，不是懲罰。** 每條政策上線前都要能回答「這會擋到誰、擋到什麼正常流程」，而不是先套用再等使用者回報。
2. **Organization 層級管緊，Folder 層級開例外。** 預設在 organization 層級用最嚴格的基準（例如 `deny_all`），實際業務需要的例外用 [`folder_overrides`](../README.md#folder-層級覆寫) 開洞，而不是反過來在 org 層級就放寬。
3. **不確定就先唯讀查證，不要用猜的寫入。** 對應 `policies_catalog.yaml` 裡 `type: unverified` 的設計：schema 或語意不明確時，先用 `gcloud org-policies describe --effective` 或 [`scripts/verify_effective_policies.sh`](../scripts/verify_effective_policies.sh) 確認現況，再決定要不要 codify。
4. **決策要留痕。** 每一條政策為什麼開／關／用什麼值，寫進 `policies_catalog.yaml` 的 `notes` 欄位或 PR 說明，而不是只存在某次會議紀錄或某人的記憶裡——半年後接手的人（可能包括未來的自己）才查得到原因。

<br>

## 決策流程

### Step 0：盤點現況

調整之前先知道「現在到底是什麼狀態」：

```bash
# 唯讀查詢全部 35 條政策的實際生效狀態，不需要事先分類
./scripts/verify_effective_policies.sh ORG_ID
```

這一步同時能發現「Google 說自動強制，但實際上帳號不合資格 / 地區還沒 rollout / 功能被改名」的落差，避免決策建立在錯誤假設上。

### Step 1：依公司自身的風險與法遵需求分類

對照公司內部已知的需求來源（不限於 CIS），把政策分成三類：

| 分類 | 判斷依據 | 範例 |
|---|---|---|
| **必須開** | 明確法遵要求（SOC2 / ISO 27001 / 產業法規）或已發生過的資安事件 | 金融業要求 Cloud SQL 不得有公開 IP → `sql.restrictPublicIp` |
| **視業務需求決定** | 沒有強制法遵要求，但方向上是好的資安實踐 | `compute.requireShieldedVm`：多數情況該開，但若有依賴舊版 VM 映像的 legacy workload 需先盤點 |
| **暫不適用** | 公司架構或工具鏈用不到，或會擋到既有正常流程 | 沒有使用服務帳戶的環境可考慮 `iam.disableServiceAccountCreation`；反之則不適用（catalog 預設就是 `enabled: false`） |

這一步的產出應該是一份「政策 → 分類 → 理由」的清單，這份清單本身就是後續 PR 說明或稽核文件的素材。

### Step 2：逐條檢視 `policies_catalog.yaml`，用以下問題決定怎麼調

對 Step 1 分類出「必須開」與「視業務需求決定」的每一條，逐一確認：

1. **這條政策目前是什麼 `type`？**
   - `boolean` / `list`：可以直接調整 `enabled`、`default_mode`、`default_values`。
   - `unverified`：先執行 `gcloud org-policies describe constraints/<id> --organization=ORG_ID --effective` 核對實際 schema，確認後才能把 `type` 改成 `boolean` 或 `list`（詳細步驟見 [README.md 的「新增一條政策」與 unverified 升級說明](../README.md#三種分類兩種-module-行為)）。切勿在還不確定值的形狀（尤其是布林方向：`enforce=true` 代表允許還是阻擋）時就猜著填。

2. **套用範圍該是 organization 還是 folder？**
   - 全公司都適用 → `attach_level: organization`。
   - 只有特定環境（例如 sandbox、legacy 系統所在的 folder）需要不同規則 → 維持 organization 層級的嚴格基準，另外用 `folder_overrides` 對特定 folder 開例外，而不是把 org 層級整個放寬。

3. **是否會擋到現有正常業務？**
   - 套用前用 `terraform plan` 確認影響範圍；高風險項目（例如 `iam.disableServiceAccountCreation`、`compute.vmExternalIpAccess`）建議先在非正式環境或單一 sandbox folder 試跑，確認不會擋到既有流程再推廣到 organization 層級。

4. **值要填什麼？**
   - 組織特定的值（Cloud Identity Customer ID、核准地區、允許的專案清單…）不要寫死在 `policies_catalog.yaml` 的 `default_values`，改用 `terraform.tfvars` 搭配 `var.value_overrides` 或 root module 既有的 `allowed_customer_ids` / `allowed_resource_locations` 傳入，讓 catalog 保持跨組織可重用。

5. **理由寫進 `notes` 欄位。** 例如：「客服部門有 3 個專案仍依賴外部 IP 對接第三方系統，故 `compute.vmExternalIpAccess` 在 org 層級維持 `deny_all`，於 `folder_overrides` 對 `customer-support` folder 開 `allow_all`，待 Q3 遷移完成後收回」。

### Step 3：修改資料而非程式碼

只需要編輯 `policies_catalog.yaml`（調整既有政策）或 `terraform.tfvars`（填組織特定值 / folder 例外），module 會用 `for_each` 自動產生對應資源，不必碰 `.tf` 檔案。這是這個 repo 選擇「資料驅動」架構的目的：讓政策調整變成審查一份 YAML/tfvars 的差異，而不是審查 Terraform 程式邏輯。

### Step 4：先小範圍驗證，再推廣

```bash
cd examples/root
terraform plan     # 確認即將產生/變更的資源符合預期
terraform apply    # 建議先對測試用 org 或 sandbox folder 執行
```

`terraform plan` 的 `unmanaged_unverified_policies` output 會列出目前仍被跳過的 unverified constraint id，可用來追蹤還有哪些待核對。

### Step 5：套用後驗證，並排入定期複查

```bash
./scripts/verify_effective_policies.sh ORG_ID
```

再跑一次唯讀腳本，確認實際生效狀態符合預期（尤其是剛升級 `type` 或剛調整 `default_mode` 的項目）。建議：

- 排進 CI 或排程（例如每週）自動執行，偵測 drift（有人在 Console 手動改了設定、或 Google 調整了 managed constraint 行為）。
- 每季（或法遵稽核週期）重新走一次 Step 1～2，因為：CIS Benchmark 會出新版、公司業務會擴張出新的例外需求、Google 也會持續新增/更名 constraint（`policies_catalog.yaml` 目前的 `auto_enforced` 分類就是持續追蹤這件事的機制）。

<br>

## 常見情境

**情境一：新業務需要對外部系統開放公開 IP，但公司整體政策是 `deny_all`**
維持 org 層級 `compute.vmExternalIpAccess: deny_all`，用 `folder_overrides` 對該業務所在的 folder 設 `allow_all` 或 `allowed_values` 白名單特定資源，並在 `notes` / PR 說明記錄理由與預計收回時間。範例見 [README.md「Folder 層級覆寫」](../README.md#folder-層級覆寫)。

**情境二：稽核要求某條 `unverified` 的自動強制政策要能證明「有生效」**
不要直接把 `enabled` 改 `true`——`type` 還是 `unverified` 的話 module 會強制跳過。先執行 `gcloud org-policies describe constraints/<id> --organization=ORG_ID --effective` 核對 API 回應是 `booleanPolicy` 還是 `listPolicy`，確認方向語意（尤其像 `cloudbuild.useBuildServiceAccount` 這種「Use X」命名，`enforce=true` 未必代表「允許」），再更新 `type` 與相關欄位。

**情境三：CIS 沒有點名，但公司自己想加一條 org policy 控制項**
直接在 `policies_catalog.yaml` 新增一個條目（`category` 可以標 `extended` 或另建自訂分類），指定 `type`、`attach_level`、`enabled`，module 不需要改 `.tf` 就會產生對應資源，見 [README.md「新增一條政策」](../README.md#新增一條政策)。

**情境四：公司規模小、目前用不到某條建議政策**
維持 catalog 中該項目 `enabled: false`，並在 `notes` 簡短記錄「目前不適用」的理由，方便日後組織成長、需求變化時快速回顧為什麼當初沒開，而不必重新從零判斷一次。

<br>

## 快速檢查清單

調整任何一條政策前，確認以下都想過一遍：

- [ ] 這條政策對應什麼具體需求（法遵條文 / 資安事件 / 業務規則）？寫得出來嗎？
- [ ] `type` 是否已確認過（不是靠猜的 `unverified`）？
- [ ] 套用層級是 organization 還是需要 folder 例外？
- [ ] 是否已用 `terraform plan` 確認過影響範圍，必要時先在 sandbox 驗證？
- [ ] 組織特定的值是否透過 `tfvars` / `value_overrides` 傳入，而不是寫死在 catalog？
- [ ] 決策理由是否已寫進 `notes` 或 PR 說明？
- [ ] 套用後是否用 `verify_effective_policies.sh` 核對過實際生效狀態？
