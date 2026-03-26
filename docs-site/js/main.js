/* ============================================================
   FlAI Documentation — Shared Layout & Interactivity
   ============================================================
   NOTE: All content injected is static/hardcoded navigation data.
   No user input is processed — no XSS risk.
   ============================================================ */

// ---- Navigation Data ----------------------------------------
// Paths are relative filenames. resolvePath() converts them to
// correct relative URLs based on the current page location.
const NAV = {
  home: 'index.html',
  sections: [
    {
      title: 'Getting Started',
      links: [
        { label: 'Introduction', href: 'docs/index.html' },
        { label: 'Installation', href: 'docs/installation.html' },
        { label: 'Theming', href: 'docs/theming.html' },
      ],
    },
    {
      title: 'Components',
      links: [
        { label: 'Chat Screen', href: 'docs/components/chat-screen.html' },
        { label: 'Message Bubble', href: 'docs/components/message-bubble.html' },
        { label: 'Input Bar', href: 'docs/components/input-bar.html' },
        { label: 'Streaming Text', href: 'docs/components/streaming-text.html' },
        { label: 'Typing Indicator', href: 'docs/components/typing-indicator.html' },
        { label: 'Tool Call Card', href: 'docs/components/tool-call-card.html' },
        { label: 'Code Block', href: 'docs/components/code-block.html' },
        { label: 'Thinking Indicator', href: 'docs/components/thinking-indicator.html' },
        { label: 'Citation Card', href: 'docs/components/citation-card.html' },
        { label: 'Image Preview', href: 'docs/components/image-preview.html' },
        { label: 'Conversation List', href: 'docs/components/conversation-list.html' },
        { label: 'Model Selector', href: 'docs/components/model-selector.html' },
        { label: 'Token Usage', href: 'docs/components/token-usage.html' },
      ],
    },
    {
      title: 'Providers',
      links: [
        { label: 'OpenAI', href: 'docs/providers/openai.html' },
        { label: 'Anthropic', href: 'docs/providers/anthropic.html' },
      ],
    },
    {
      title: 'Integrations',
      links: [
        { label: 'App Scaffolds', href: 'docs/scaffolds.html' },
        { label: 'MCP Server', href: 'docs/mcp.html' },
        { label: 'Claude Code Skill', href: 'docs/skill.html' },
      ],
    },
  ],
};

// ---- Resolve Relative Paths ---------------------------------
// Convert a site-root-relative path (e.g. "docs/components/chat-screen.html")
// to a proper relative URL from the current page.
function resolvePath(href) {
  const currentPath = window.location.pathname;
  // Determine the "base" directory of the current page
  // e.g. "/docs/components/chat-screen.html" -> depth 3 (below site root)
  // We need to find the site root, then compute relative path from current page.

  // Find how deep the current page is relative to the site root.
  // The site root is wherever index.html lives.
  // Heuristic: count path segments from the current page back to where
  // main.js is loaded from (always ../js/main.js or js/main.js from root pages).

  // Simpler approach: use the <base> tag or compute from known structure.
  // Current pages are at: /, /docs/, /docs/components/, /docs/providers/
  // href is always relative to site root.

  // Count directories in current pathname (excluding filename)
  const segments = currentPath.split('/').filter(Boolean);
  // Remove the filename (last segment with .html)
  if (segments.length > 0 && segments[segments.length - 1].includes('.')) {
    segments.pop();
  }

  // Count how many dirs deep we are from server root
  const depth = segments.length;
  const prefix = depth > 0 ? '../'.repeat(depth) : './';
  return prefix + href;
}

// ---- Build Header (using DOM APIs) --------------------------
function injectHeader() {
  const header = document.getElementById('site-header');
  if (!header) return;

  const currentPath = window.location.pathname;
  const isDocs = currentPath.includes('/docs/');

  const inner = document.createElement('div');
  inner.className = 'header-inner';

  // Logo
  const logoLink = document.createElement('a');
  logoLink.href = resolvePath('index.html');
  logoLink.className = 'header-logo';
  const badge = document.createElement('span');
  badge.className = 'logo-badge';
  const logoSvg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  logoSvg.setAttribute('viewBox', '0 0 100 100');
  logoSvg.setAttribute('width', '18');
  logoSvg.setAttribute('height', '18');
  logoSvg.setAttribute('fill', 'none');
  const logoDefs = document.createElementNS('http://www.w3.org/2000/svg', 'defs');
  const logoGrad = document.createElementNS('http://www.w3.org/2000/svg', 'linearGradient');
  logoGrad.setAttribute('id', 'logo-grad');
  logoGrad.setAttribute('x1', '0%'); logoGrad.setAttribute('y1', '0%');
  logoGrad.setAttribute('x2', '100%'); logoGrad.setAttribute('y2', '100%');
  const stop1 = document.createElementNS('http://www.w3.org/2000/svg', 'stop');
  stop1.setAttribute('offset', '0%'); stop1.setAttribute('stop-color', '#6366F1');
  const stop2 = document.createElementNS('http://www.w3.org/2000/svg', 'stop');
  stop2.setAttribute('offset', '100%'); stop2.setAttribute('stop-color', '#8B5CF6');
  logoGrad.appendChild(stop1); logoGrad.appendChild(stop2);
  logoDefs.appendChild(logoGrad);
  logoSvg.appendChild(logoDefs);
  const wing1 = document.createElementNS('http://www.w3.org/2000/svg', 'path');
  wing1.setAttribute('d', 'M50 10 L90 50 L72 68 L32 28 Z');
  wing1.setAttribute('fill', 'url(#logo-grad)');
  logoSvg.appendChild(wing1);
  const wing2 = document.createElementNS('http://www.w3.org/2000/svg', 'path');
  wing2.setAttribute('d', 'M28 32 L68 72 L50 90 L10 50 Z');
  wing2.setAttribute('fill', 'url(#logo-grad)');
  wing2.setAttribute('opacity', '0.75');
  logoSvg.appendChild(wing2);
  badge.appendChild(logoSvg);
  logoLink.appendChild(badge);
  logoLink.appendChild(document.createTextNode(' FlAI'));
  inner.appendChild(logoLink);

  // Nav
  const nav = document.createElement('nav');
  nav.className = 'header-nav';
  const isBlueprints = currentPath.includes('blueprints');
  const navItems = [
    { label: 'Docs', href: 'docs/index.html', active: isDocs },
    { label: 'Components', href: 'docs/components/chat-screen.html', active: false },
    { label: 'Theming', href: 'docs/theming.html', active: false },
    { label: 'Blueprints', href: 'blueprints.html', active: isBlueprints },
  ];
  navItems.forEach(item => {
    const a = document.createElement('a');
    a.href = resolvePath(item.href);
    a.textContent = item.label;
    if (item.active) a.className = 'active';
    nav.appendChild(a);
  });
  inner.appendChild(nav);

  // Right section
  const right = document.createElement('div');
  right.className = 'header-right';

  const ghLink = document.createElement('a');
  ghLink.href = 'https://github.com/getflai-dev/flai';
  ghLink.target = '_blank';
  ghLink.className = 'header-gh';
  ghLink.setAttribute('aria-label', 'GitHub');
  const ghSvg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  ghSvg.setAttribute('viewBox', '0 0 24 24');
  const ghPath = document.createElementNS('http://www.w3.org/2000/svg', 'path');
  ghPath.setAttribute('d', 'M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0024 12c0-6.63-5.37-12-12-12z');
  ghSvg.appendChild(ghPath);
  ghLink.appendChild(ghSvg);
  ghLink.appendChild(document.createTextNode(' GitHub'));
  right.appendChild(ghLink);

  // Mobile toggle
  const mobileBtn = document.createElement('button');
  mobileBtn.className = 'mobile-toggle';
  mobileBtn.setAttribute('aria-label', 'Toggle menu');
  mobileBtn.addEventListener('click', toggleSidebar);
  const menuSvg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  menuSvg.setAttribute('viewBox', '0 0 24 24');
  menuSvg.setAttribute('fill', 'none');
  menuSvg.setAttribute('stroke', 'currentColor');
  menuSvg.setAttribute('stroke-width', '2');
  menuSvg.setAttribute('stroke-linecap', 'round');
  [6, 12, 18].forEach(y => {
    const line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
    line.setAttribute('x1', '3'); line.setAttribute('y1', String(y));
    line.setAttribute('x2', '21'); line.setAttribute('y2', String(y));
    menuSvg.appendChild(line);
  });
  mobileBtn.appendChild(menuSvg);
  right.appendChild(mobileBtn);

  inner.appendChild(right);
  header.appendChild(inner);
}

// ---- Build Sidebar (using DOM APIs) -------------------------
function injectSidebar() {
  const sidebar = document.getElementById('sidebar');
  if (!sidebar) return;

  const currentPath = window.location.pathname;

  NAV.sections.forEach(section => {
    const div = document.createElement('div');
    div.className = 'sidebar-section';

    const title = document.createElement('div');
    title.className = 'sidebar-section-title';
    title.textContent = section.title;
    div.appendChild(title);

    section.links.forEach(link => {
      const a = document.createElement('a');
      a.href = resolvePath(link.href);
      a.className = 'sidebar-link';
      a.textContent = link.label;

      const linkFile = link.href.split('/').pop();
      if (currentPath.endsWith(linkFile)) {
        a.classList.add('active');
      }
      div.appendChild(a);
    });

    sidebar.appendChild(div);
  });
}

// ---- Build Table of Contents (auto-generated from h2/h3) ----
function injectTOC() {
  const toc = document.getElementById('toc');
  if (!toc) return;

  const headings = document.querySelectorAll('.content-inner h2, .content-inner h3');
  if (headings.length === 0) {
    toc.style.display = 'none';
    return;
  }

  const tocTitle = document.createElement('div');
  tocTitle.className = 'toc-title';
  tocTitle.textContent = 'On This Page';
  toc.appendChild(tocTitle);

  headings.forEach(h => {
    if (!h.id) {
      h.id = h.textContent.toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/(^-|-$)/g, '');
    }
    const a = document.createElement('a');
    a.href = '#' + h.id;
    a.className = 'toc-link';
    a.textContent = h.textContent;
    if (h.tagName === 'H3') {
      a.style.paddingLeft = '18px';
    }
    toc.appendChild(a);
  });

  // Intersection observer for active state
  const observer = new IntersectionObserver(
    entries => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          toc.querySelectorAll('.toc-link').forEach(l => l.classList.remove('active'));
          const link = toc.querySelector('a[href="#' + entry.target.id + '"]');
          if (link) link.classList.add('active');
        }
      });
    },
    { rootMargin: '-80px 0px -70% 0px' }
  );

  headings.forEach(h => observer.observe(h));
}

// ---- Mobile Sidebar Toggle ----------------------------------
function toggleSidebar() {
  const sidebar = document.getElementById('sidebar');
  const overlay = document.getElementById('sidebar-overlay');
  if (sidebar) sidebar.classList.toggle('open');
  if (overlay) overlay.classList.toggle('open');
}

// ---- Copy Code Button Logic ---------------------------------
function initCopyButtons() {
  document.querySelectorAll('.copy-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      let text = '';

      const target = btn.dataset.target;
      if (target) {
        const el = document.getElementById(target);
        if (el) text = el.textContent;
      } else {
        const codeBlock = btn.closest('.code-block');
        const installCmd = btn.closest('.install-cmd');
        if (codeBlock) {
          const code = codeBlock.querySelector('code');
          if (code) text = code.textContent;
        } else if (installCmd) {
          const cmdText = installCmd.querySelector('.cmd-text');
          if (cmdText) text = cmdText.textContent;
        }
      }

      if (text) {
        navigator.clipboard.writeText(text.trim()).then(() => {
          btn.classList.add('copied');
          const origNodes = Array.from(btn.childNodes).map(n => n.cloneNode(true));
          btn.textContent = '';
          const checkSvg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
          checkSvg.setAttribute('width', '12');
          checkSvg.setAttribute('height', '12');
          checkSvg.setAttribute('viewBox', '0 0 24 24');
          checkSvg.setAttribute('fill', 'none');
          checkSvg.setAttribute('stroke', 'currentColor');
          checkSvg.setAttribute('stroke-width', '2.5');
          checkSvg.setAttribute('stroke-linecap', 'round');
          checkSvg.setAttribute('stroke-linejoin', 'round');
          const polyline = document.createElementNS('http://www.w3.org/2000/svg', 'polyline');
          polyline.setAttribute('points', '20 6 9 17 4 12');
          checkSvg.appendChild(polyline);
          btn.appendChild(checkSvg);
          btn.appendChild(document.createTextNode(' Copied'));

          setTimeout(() => {
            btn.classList.remove('copied');
            btn.textContent = '';
            origNodes.forEach(n => btn.appendChild(n));
          }, 2000);
        });
      }
    });
  });
}

// ---- Wrap Code Blocks with Header ---------------------------
function enhanceCodeBlocks() {
  document.querySelectorAll('pre > code[class*="language-"]').forEach(code => {
    const pre = code.parentElement;
    if (pre.dataset.enhanced) return;
    pre.dataset.enhanced = 'true';

    const langMatch = code.className.match(/language-(\w+)/);
    const lang = langMatch ? langMatch[1] : '';

    const wrapper = document.createElement('div');
    wrapper.className = 'code-block';

    const header = document.createElement('div');
    header.className = 'code-header';

    const langSpan = document.createElement('span');
    langSpan.className = 'code-lang';
    langSpan.textContent = lang;
    header.appendChild(langSpan);

    const copyBtn = document.createElement('button');
    copyBtn.className = 'copy-btn';
    const copySvg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    copySvg.setAttribute('width', '12');
    copySvg.setAttribute('height', '12');
    copySvg.setAttribute('viewBox', '0 0 24 24');
    copySvg.setAttribute('fill', 'none');
    copySvg.setAttribute('stroke', 'currentColor');
    copySvg.setAttribute('stroke-width', '2');
    copySvg.setAttribute('stroke-linecap', 'round');
    copySvg.setAttribute('stroke-linejoin', 'round');
    const rect = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
    rect.setAttribute('x', '9'); rect.setAttribute('y', '9');
    rect.setAttribute('width', '13'); rect.setAttribute('height', '13');
    rect.setAttribute('rx', '2'); rect.setAttribute('ry', '2');
    copySvg.appendChild(rect);
    const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    path.setAttribute('d', 'M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1');
    copySvg.appendChild(path);
    copyBtn.appendChild(copySvg);
    copyBtn.appendChild(document.createTextNode(' Copy'));
    header.appendChild(copyBtn);

    pre.parentNode.insertBefore(wrapper, pre);
    wrapper.appendChild(header);
    wrapper.appendChild(pre);
  });
}

// ---- Inject Shared Head Assets ------------------------------
// Fonts, Prism CSS, and favicon — injected once so HTML files
// don't need to duplicate these links.
function injectHeadAssets() {
  // Favicon
  const favicon = document.createElement('link');
  favicon.rel = 'icon';
  favicon.type = 'image/svg+xml';
  favicon.href = resolvePath('favicon.svg');
  document.head.appendChild(favicon);

  // Google Fonts (Inter + JetBrains Mono)
  if (!document.querySelector('link[href*="fonts.googleapis.com"]')) {
    const preconnect1 = document.createElement('link');
    preconnect1.rel = 'preconnect';
    preconnect1.href = 'https://fonts.googleapis.com';
    document.head.appendChild(preconnect1);

    const preconnect2 = document.createElement('link');
    preconnect2.rel = 'preconnect';
    preconnect2.href = 'https://fonts.gstatic.com';
    preconnect2.crossOrigin = '';
    document.head.appendChild(preconnect2);

    const fonts = document.createElement('link');
    fonts.rel = 'stylesheet';
    fonts.href = 'https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500&display=swap';
    document.head.appendChild(fonts);
  }

  // Prism.js theme
  if (!document.querySelector('link[href*="prismjs"]')) {
    const prism = document.createElement('link');
    prism.rel = 'stylesheet';
    prism.href = 'https://cdn.jsdelivr.net/npm/prismjs@1.29.0/themes/prism-tomorrow.min.css';
    document.head.appendChild(prism);
  }
}

// ---- Inject SEO Meta Tags -----------------------------------
// Adds canonical, Open Graph, Twitter Card, and meta description
// to doc pages that don't already have them.
function injectSEOMeta() {
  const SITE_URL = 'https://getflai.dev';
  const SITE_NAME = 'FlAI';
  const DEFAULT_IMAGE = SITE_URL + '/og-image.png';

  // Skip homepage — it has its own meta tags
  if (document.body.classList.contains('homepage-layout')) return;

  const title = document.title || SITE_NAME;
  const pageDesc = document.querySelector('.page-desc');
  const description = pageDesc
    ? pageDesc.textContent.trim()
    : title.replace(' — FlAI Docs', '') + ' component for Flutter AI chat interfaces. Part of the FlAI component library.';

  // Build canonical URL from pathname
  const path = window.location.pathname.replace(/\/+$/, '') || '/';
  const canonicalUrl = SITE_URL + path;

  function addMeta(attr, attrVal, content) {
    if (document.querySelector('meta[' + attr + '="' + attrVal + '"]')) return;
    const meta = document.createElement('meta');
    meta.setAttribute(attr, attrVal);
    meta.content = content;
    document.head.appendChild(meta);
  }

  function addLink(rel, href) {
    if (document.querySelector('link[rel="' + rel + '"]')) return;
    const link = document.createElement('link');
    link.rel = rel;
    link.href = href;
    document.head.appendChild(link);
  }

  // Meta description
  if (!document.querySelector('meta[name="description"]')) {
    addMeta('name', 'description', description);
  }

  // Canonical
  addLink('canonical', canonicalUrl);

  // Robots
  addMeta('name', 'robots', 'index, follow');

  // Open Graph
  addMeta('property', 'og:type', 'article');
  addMeta('property', 'og:title', title);
  addMeta('property', 'og:description', description);
  addMeta('property', 'og:url', canonicalUrl);
  addMeta('property', 'og:site_name', SITE_NAME);
  addMeta('property', 'og:image', DEFAULT_IMAGE);

  // Twitter Card
  addMeta('name', 'twitter:card', 'summary_large_image');
  addMeta('name', 'twitter:title', title);
  addMeta('name', 'twitter:description', description);
  addMeta('name', 'twitter:image', DEFAULT_IMAGE);
}

// ---- Init ---------------------------------------------------
document.addEventListener('DOMContentLoaded', () => {
  injectHeadAssets();
  injectSEOMeta();
  injectHeader();
  injectSidebar();
  injectTOC();

  // Sidebar overlay click to close
  const overlay = document.getElementById('sidebar-overlay');
  if (overlay) {
    overlay.addEventListener('click', toggleSidebar);
  }

  // Wait a tick for Prism to finish, then enhance
  setTimeout(() => {
    enhanceCodeBlocks();
    initCopyButtons();
  }, 100);
});
