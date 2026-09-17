// @ts-check
import {themes as prismThemes} from 'prism-react-renderer';

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'GCP Enterprise Onboarding',
  tagline: 'Enterprise-tier Google Cloud onboarding guide',
  favicon: 'img/favicon.svg',

  future: {
    v4: true,
  },

  // GitHub Pages (project page) production URL.
  url: 'https://terensy.github.io',
  baseUrl: '/gcp-onboarding-workflow/',

  organizationName: 'terensy',
  projectName: 'gcp-onboarding-workflow',
  trailingSlash: false,

  onBrokenLinks: 'throw',
  onBrokenAnchors: 'throw',
  markdown: {
    hooks: {
      onBrokenMarkdownLinks: 'warn',
    },
  },

  i18n: {
    defaultLocale: 'zh-Hant',
    locales: ['zh-Hant', 'en-GB'],
    localeConfigs: {
      'zh-Hant': {
        label: '繁體中文',
        htmlLang: 'zh-Hant-TW',
        direction: 'ltr',
      },
      'en-GB': {
        label: 'English',
        htmlLang: 'en-GB',
        direction: 'ltr',
      },
    },
  },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          routeBasePath: '/', // serve docs at the site root
          sidebarPath: './sidebars.js',
          editUrl: 'https://github.com/terensy/gcp-onboarding-workflow/tree/main/site/',
          showLastUpdateTime: true,
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
        sitemap: {
          changefreq: 'weekly',
          priority: 0.5,
          ignorePatterns: ['/tags/**'],
        },
        gtag: undefined,
      }),
    ],
  ],

  // Global structured data (JSON-LD) — helps both traditional search engines
  // and AI answer engines (AEO) understand what this site/organization is.
  headTags: [
    {
      tagName: 'script',
      attributes: {type: 'application/ld+json'},
      innerHTML: JSON.stringify({
        '@context': 'https://schema.org',
        '@type': 'WebSite',
        name: 'GCP Enterprise Onboarding',
        url: 'https://terensy.github.io/gcp-onboarding-workflow/',
        description:
          'An enterprise-tier Google Cloud Platform onboarding guide covering Cloud Identity, IAM, networking, logging, security and Terraform automation.',
        inLanguage: ['zh-Hant', 'en-GB'],
      }),
    },
    {
      tagName: 'script',
      attributes: {type: 'application/ld+json'},
      innerHTML: JSON.stringify({
        '@context': 'https://schema.org',
        '@type': 'TechArticle',
        about: 'Google Cloud Platform enterprise onboarding',
        publisher: {
          '@type': 'Organization',
          name: 'terensy',
          url: 'https://github.com/terensy',
        },
      }),
    },
    {
      tagName: 'meta',
      attributes: {name: 'robots', content: 'index, follow, max-image-preview:large'},
    },
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      metadata: [
        {name: 'keywords', content: 'GCP, Google Cloud, enterprise onboarding, IAM, Terraform, org policy'},
      ],
      colorMode: {
        respectPrefersColorScheme: true,
      },
      navbar: {
        title: 'GCP Onboarding',
        logo: {
          alt: 'GCP Enterprise Onboarding logo',
          src: 'img/logo.svg',
        },
        items: [
          {
            type: 'docSidebar',
            sidebarId: 'guideSidebar',
            position: 'left',
            label: 'Guide',
          },
          {
            href: 'https://github.com/terensy/gcp-onboarding-workflow',
            label: 'GitHub',
            position: 'right',
          },
          {
            type: 'localeDropdown',
            position: 'right',
          },
        ],
      },
      footer: {
        style: 'dark',
        links: [
          {
            title: 'Guide',
            items: [
              {
                label: 'Cloud Identity',
                to: '/cloud-identity/verify-domain',
              },
              {
                label: 'Organization Setup',
                to: '/organization-setup/folders-projects',
              },
              {
                label: 'Network Design',
                to: '/network-design/architecture',
              },
              {
                label: 'SME Quickstart',
                to: '/sme-quickstart/overview',
              },
              {
                label: 'AI Onboarding',
                to: '/ai-onboarding/overview',
              },
            ],
          },
          {
            title: 'Terraform modules',
            items: [
              {
                label: 'organization-policies',
                href: 'https://github.com/terensy/gcp-onboarding-workflow/tree/main/organization-policies',
              },
              {
                label: 'network-design',
                href: 'https://github.com/terensy/gcp-onboarding-workflow/tree/main/network-design',
              },
              {
                label: 'security-products',
                href: 'https://github.com/terensy/gcp-onboarding-workflow/tree/main/security-products',
              },
              {
                label: 'sme-quickstart',
                href: 'https://github.com/terensy/gcp-onboarding-workflow/tree/main/sme-quickstart',
              },
              {
                label: 'ai-onboarding',
                href: 'https://github.com/terensy/gcp-onboarding-workflow/tree/main/ai-onboarding',
              },
            ],
          },
          {
            title: 'More',
            items: [
              {
                label: 'GitHub Repository',
                href: 'https://github.com/terensy/gcp-onboarding-workflow',
              },
              {
                label: 'llms.txt',
                to: 'pathname:///llms.txt',
              },
            ],
          },
        ],
        copyright: `Copyright © ${new Date().getFullYear()} terensy. Built with Docusaurus.`,
      },
      prism: {
        theme: prismThemes.github,
        darkTheme: prismThemes.dracula,
        additionalLanguages: ['hcl', 'yaml', 'bash'],
      },
    }),
};

export default config;
