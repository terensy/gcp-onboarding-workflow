# GCP Enterprise Onboarding — Docs Site

Bilingual (Traditional Chinese / British English) Docusaurus site for the guide in this repository's root [README.md](../README.md), published to GitHub Pages at <https://terensy.github.io/gcp-onboarding-workflow/>.

## Local development

```bash
npm install
npm start
```

Starts a local dev server with live reload. Add `-- --locale en-GB` to preview the English build (`npm start -- --locale en-GB`).

## Build

```bash
npm run build
```

Builds both locales into `build/` (`zh-Hant` at the root, `en-GB` under `build/en-GB/`). `onBrokenLinks`/`onBrokenAnchors` are set to `throw`, so a broken internal link fails the build — treat that as a real error, not a warning to ignore.

```bash
npm run serve
```

Serves the built output locally to sanity-check the production build before pushing.

## Content structure

- `docs/` — the default-locale (Traditional Chinese) content. Folder/file names are numerically prefixed (`01-`, `02-`, …) purely to control sidebar order; Docusaurus strips the prefix from the actual URL (e.g. `docs/02-organization-setup/billing.md` is served at `/organization-setup/billing`, **not** `/02-organization-setup/billing`) — keep that in mind when writing internal links.
- `i18n/en-GB/docusaurus-plugin-content-docs/current/` — the English translation, mirroring `docs/` path-for-path (minus the `_category_.json` files — those are translated via `i18n/en-GB/docusaurus-plugin-content-docs/current.json` instead).
- `i18n/en-GB/docusaurus-theme-classic/` and `code.json` — theme/navbar/footer UI string translations, generated with `npm run write-translations -- --locale en-GB` and then hand-translated.
- `static/img/diagrams/` — copies of the official Google architecture diagrams also used in the root README's `images/` folder. `static/llms.txt` and `static/robots.txt` are the AEO/SEO entry points.

## Adding a new page

1. Add the Traditional Chinese `.md` file under `docs/` (with front matter: `title`, `description`, `keywords`, `sidebar_position`).
2. Add the matching English `.md` file at the identical relative path under `i18n/en-GB/docusaurus-plugin-content-docs/current/`.
3. If you added a new category folder, add a `_category_.json` in `docs/`, then add its `sidebar.guideSidebar.category.<label>` and `...link.generated-index.description` keys to `i18n/en-GB/docusaurus-plugin-content-docs/current.json`.
4. Run `npm run build` — a missing English translation doesn't fail the build (Docusaurus falls back to the Chinese content for any untranslated page), so this won't catch a forgotten translation. Check the page manually with `npm start -- --locale en-GB`.
5. Add the new page to `static/llms.txt`.

## Deployment

Handled by [`.github/workflows/deploy-docs.yml`](../.github/workflows/deploy-docs.yml) — every push to `main` that touches `site/**` builds the site and deploys it to GitHub Pages via `actions/deploy-pages`. There's no manual `npm run deploy` step; don't use the Docusaurus-default `USE_SSH=true npm run deploy` / `gh-pages` branch workflow described in Docusaurus's own docs — this repo deploys straight from the Actions build artifact, not a `gh-pages` branch.
