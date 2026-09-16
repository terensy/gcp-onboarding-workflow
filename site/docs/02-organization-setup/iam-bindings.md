---
title: IAM 角色指派
description: 把管理群組實際綁定到 GCP IAM 角色——最小權限原則、Predefined role、群組繼承、Deny 政策與 PAM。
keywords: [GCP IAM, IAM binding, least privilege, Predefined role, IAM Deny]
sidebar_position: 4
---

# 2.4 IAM 角色指派

[User 來源與群組規劃](/cloud-identity/user-groups)建立的 5 個群組，這裡才是真正把權限「兌現」的地方。[Google IAM 安全性最佳實務](https://cloud.google.com/iam/docs/using-iam-securely) 講得很直白：

:::info
正式環境除非真的沒有其他選擇，不要授予 Basic role（Owner / Editor / Viewer）。優先用 Google 維護的 Predefined role，把角色綁在**群組**而不是個人帳號上——[Google 自家的 Enterprise Foundations Blueprint](https://cloud.google.com/architecture/blueprints/security-foundations/authentication-authorization) 用的正是同一套「依職能分組、角色綁群組」的模式。
:::

![IAM 政策沿資源階層繼承示意圖](/img/diagrams/iam-policy-inheritance.svg)

IAM 政策沿著 Organization → Folder → Project → 資源往下**繼承**，且只會疊加、不會被下層限縮——在 Organization 層級給的角色，會自動套用到底下所有 Folder 和 Project。這代表兩件事：

1. 綁在越高層的角色，影響範圍越大，出錯的代價也越大，所以這 5 個群組全部綁在 Organization 層級是刻意的決定，不是隨便。
2. 不需要（也不應該）在每個 Project 重複手動授權——如果發現同一個角色要在幾十個 Project 分別設定一次，代表群組跟階層規劃有問題，該回頭檢查 [Folder 規劃](/organization-setup/folders-projects)，而不是繼續手動疊加。

實際綁定用 [`iam-bindings/`](https://github.com/terensy/gcp-onboarding-workflow/tree/main/iam-bindings) 子專案的 Terraform module，讀取 `bindings_catalog.yaml` 直接把 5 個群組綁到對應角色。這個 module 分開處理 Organization 層級與 Billing 帳戶層級兩種綁定。

:::tip
除了長期綁定的角色，[Privileged Access Manager (PAM)](https://cloud.google.com/iam/docs/pam-overview) 可以做到「臨時提權，用完自動收回」——像 Organization Administrator 這種高風險角色，比較嚴謹的做法是平常不給常態權限，需要操作時才申請一段時間的 PAM 授權，操作完自動失效，不用等人工去收回。
:::

:::danger
「先都給 Owner，之後再慢慢調」是一個常見但危險的捷徑——這個「之後」往往永遠不會來，因為權限只會越開越大方，很少有人願意主動把已經在用的權限收回去（怕收錯擋到別人）。等到真的出資安事件要回溯「誰有權限碰這個資料庫」，才發現一半的人都是 Owner，查了等於沒查。想從根本解決，用 [IAM Deny 政策](https://cloud.google.com/iam/docs/deny-overview) 明確擋掉 Basic role（Deny 政策的優先權高於任何 Allow，擋了就是擋了），從一開始就不留「之後再調」的模糊空間。
:::
