---
title: Create GCP folders and projects
description: Plan a GCP folder hierarchy and create projects — three common patterns based on application environment, region/subsidiary, or accountability structure.
keywords: [GCP folder, GCP project, resource hierarchy]
sidebar_position: 1
---

# 2.1 Create GCP Folders & Projects

Once the super admin logs into the GCP console, the single most important task is granting the User accounts or groups you just created the roles they need. After that's done, the super admin can log out and hand day-to-day GCP setup and use over to the people holding those roles.

You create GCP folders to organise and partition GCP projects, and to apply org policies or user/group permissions at the folder level.

- You can [build a hierarchy based on application environment](https://docs.cloud.google.com/architecture/landing-zones/decide-resource-hierarchy?hl=en#option1)

![Hierarchy based on application environment](/img/diagrams/hierarchy-based-on-ap-env.svg)

- Or [build a hierarchy based on region or subsidiary](https://docs.cloud.google.com/architecture/landing-zones/decide-resource-hierarchy?hl=en#option2)

![Hierarchy based on regions or subsidiaries](/img/diagrams/hierarchy-based-on-regions-or-subsidiaries.svg)

- Or [build a hierarchy based on an accountability framework](https://docs.cloud.google.com/architecture/landing-zones/decide-resource-hierarchy?hl=en#option3)

![Hierarchy based on an accountability framework](/img/diagrams/hierarchy-based-on-accountability-framework.svg)

There's no single right answer for hierarchy design — you can plan it around whatever your organisation needs, and you can even skip GCP folders altogether; it comes down entirely to your company's internal governance policy for systems and services. Whichever model you pick, it's common to carve out an additional shared-services folder to centrally manage common components like networking, audit logs and CI/CD, then expand the folders for each application/environment/subsidiary underneath it according to your chosen model. Once the GCP folder hierarchy is in place, you can create the GCP projects you need inside it and start using GCP services.

Finally, if you're struggling with folder or project naming, refer to [Google's recommended folder and project naming conventions](https://docs.cloud.google.com/architecture/blueprints/security-foundations/summary?hl=en#naming-conventions).
