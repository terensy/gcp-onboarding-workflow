---
title: 建立 GCP Folder 與 Project
description: 規劃 GCP Folder 階層並建立 Project——依應用程式環境、依區域/子公司，或依問責架構三種常見模式。
keywords: [GCP Folder, GCP Project, resource hierarchy, 資源階層]
sidebar_position: 1
---

# 2.1 建立 GCP Folder & Project

當超級管理員登入到 GCP console，最重要的一件事是幫剛剛建立的 User account 或是群組給予對應角色所需要的權限。完成之後就可以登出超級管理員交給對應角色的內部人員進行 GCP 初始化設定或使用。

建立 GCP Folder 是為了有組織的管理跟劃分 GCP Project，另外就是以 Folder 為單位的給予組織政策或是使用者或群組權限。

- 可以[根據應用程式環境建立階層](https://docs.cloud.google.com/architecture/landing-zones/decide-resource-hierarchy?hl=zh-tw#option1)

![依應用程式環境建立階層](/img/diagrams/hierarchy-based-on-ap-env.svg)

- 也可以[按區域或子公司建立階層](https://docs.cloud.google.com/architecture/landing-zones/decide-resource-hierarchy?hl=zh-tw#option2)

![依區域或子公司建立階層](/img/diagrams/hierarchy-based-on-regions-or-subsidiaries.svg)

- 或是[根據問責架構建立階層](https://docs.cloud.google.com/architecture/landing-zones/decide-resource-hierarchy?hl=zh-tw#option3)

![依問責架構建立階層](/img/diagrams/hierarchy-based-on-accountability-framework.svg)

階層規劃沒有一定的答案，可以根據內部所需規劃甚至也可以不用 GCP Folder，全憑公司內部對於系統服務上的管理政策。不論選擇上述哪一種模式，通常都會額外規劃一個共用服務用的 Folder，把網路、Audit Log、CI/CD 等共用元件集中管理，再往下依所選模式展開各應用/環境/子公司的 Folder。GCP Folder 階層建立完成後就可以在裡面建立所需要的 GCP Project 開始使用 GCP 服務了。

最後，如果對於 GCP Folder、Project 命名有困難，可以參考 [Google 規劃的 Folder 跟 Project 命名規則](https://docs.cloud.google.com/architecture/blueprints/security-foundations/summary?hl=zh-tw#naming-conventions)。
