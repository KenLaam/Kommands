---
description: Convert a markdown file to a polished standalone HTML page (auto dark/light theme, callouts, badges, copy-able code blocks, sticky TOC with scroll-spy).
argument-hint: "<input.md> [output.html]"
---

# md2html

Convert a markdown file to a styled standalone HTML page using a fixed design system: auto dark/light theme, file pills, callouts, numbered steps, code blocks with copy buttons, and a pinned right-side table of contents with scroll-spy (auto-generated from H2s, hidden on narrow viewports). Output is a single self-contained file (no external CSS/JS).

## Arguments

`$ARGUMENTS` — space-separated:
1. **Required:** input markdown path
2. **Optional:** output HTML path. If omitted, write next to the source with `.md` swapped for `.html`.

## Workflow

1. **Read** the input markdown with the Read tool.
2. **Resolve output path:** use second arg if provided, else replace trailing `.md` with `.html` in input path.
3. **Translate** to HTML using the mapping rules below.
4. **Wrap** with the scaffold below (paste CSS + JS verbatim — do not modify variables, classes, or the copy-button script).
5. **Write** the final HTML via Write tool.
6. Report: destination path, byte size, and a 1-line note on any markdown structures that didn't map cleanly.

## Mapping Rules (Markdown → HTML)

| Markdown | HTML |
|---|---|
| `# Title` (first H1 only) | `<header class="hero">` with `<h1>` inside. If the H1 has a bolded prefix like `**TODO —** Title`, lift that prefix into `<div class="eyebrow">…</div>` above the `<h1>`. |
| `## Section` | `<h2>` |
| `### Sub` | `<h3>` |
| Paragraph starting with `**Why:**`, `**Note:**`, `**Source layout:**`, etc. | `<div class="callout">` with `<div class="callout-title">…</div>` and the rest as the body. |
| Paragraph starting with `**Warning:**`, `**Important:**`, `**Cannot Automate:**`, `**Caution:**`, `**Do not …**` | `<div class="callout warn">` (same structure). |
| Numbered lists where items read as sequential actions | `<ol class="steps">` — auto-numbered cards |
| Other numbered/bulleted lists | plain `<ol>` / `<ul>` |
| Inline backticks with file paths or filenames (contains `/` or ends with a known extension `.swift .ts .js .py .sh .plist .json .yaml .yml .xcconfig .md`) | `<span class="file-pill">…</span>` |
| Other inline backticks | `<code>…</code>` |
| Fenced code block ```` ```lang ```` | `<pre><code>…</code></pre>` (no language class needed; copy button auto-attached by JS) |
| `<kbd>X</kbd>` literals OR phrasing like "press +" / "click +" / "Cmd+S" | `<kbd>X</kbd>` |
| Tables | plain `<table>` (no special class) |
| Bold/italic | `<strong>` / `<em>` |
| Links | `<a href="…">…</a>` |
| Horizontal rule `---` | `<hr>` |

**Code block readability rule:** any value the reader is expected to copy (Xcode field values, shell commands, file paths) MUST be in a `<pre><code>` block — never inline `<code>`. Use `<pre class="value"><code>…</code></pre>` for short single-line values (renders tighter).

**Grid cards:** if two adjacent fenced code blocks share a common context (e.g. "Production scheme" / "Beta scheme" command pair), wrap them in `<div class="grid-2">` with each in `<div class="card"><div class="card-title">…</div><pre>…</pre></div>`. Optional — use judgment.

**Badges:** if the H1 area has parenthetical metadata like `(Manual UI · ~30 seconds)`, render as `<span class="badge">…</span>` chips below the title. Use `.badge.warn` for cautions, `.badge.ok` for "Final"/"Done" markers.

**Title:** use the first H1's text as `<title>`. If absent, use input file basename.

## HTML Scaffold

Output structure:

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{{TITLE}}</title>
<style>
  /* paste CSS block below verbatim */
</style>
</head>
<body>
<div class="page">
  {{CONVERTED CONTENT}}
</div>
<script>
  /* paste JS block below verbatim */
</script>
</body>
</html>
```

### CSS (paste verbatim)

```css
:root {
  --bg: #0d1117;
  --bg-elev: #11161d;
  --panel: #161b22;
  --panel-2: #1c2128;
  --panel-hover: #20262e;
  --border: #2d343d;
  --border-strong: #3a424c;
  --text: #f0f6fc;
  --text-muted: #b1bac4;
  --text-faint: #8b949e;
  --accent: #79b8ff;
  --accent-strong: #58a6ff;
  --accent-soft: #1f6feb33;
  --warn: #f0b429;
  --warn-text: #f9d77a;
  --warn-soft: #d2992226;
  --warn-border: #d29922;
  --ok: #56d364;
  --ok-text: #56d364;
  --code-bg: #0a0e14;
  --code-border: #2d343d;
  --kbd-bg: #21262d;
  --shadow-sm: 0 1px 2px rgba(0,0,0,0.4);
  --shadow-md: 0 4px 12px rgba(0,0,0,0.35);
}
@media (prefers-color-scheme: light) {
  :root {
    --bg: #ffffff;
    --bg-elev: #fafbfc;
    --panel: #f6f8fa;
    --panel-2: #ffffff;
    --panel-hover: #eef1f4;
    --border: #d8dde3;
    --border-strong: #afb8c1;
    --text: #0a0c10;
    --text-muted: #424a53;
    --text-faint: #6e7781;
    --accent: #0550ae;
    --accent-strong: #0969da;
    --accent-soft: #ddf4ff;
    --warn: #7d4e00;
    --warn-text: #7d4e00;
    --warn-soft: #fff8c5;
    --warn-border: #d4a72c;
    --ok: #1a7f37;
    --ok-text: #1a7f37;
    --code-bg: #f6f8fa;
    --code-border: #d8dde3;
    --kbd-bg: #f6f8fa;
    --shadow-sm: 0 1px 2px rgba(0,0,0,0.06);
    --shadow-md: 0 4px 12px rgba(0,0,0,0.08);
  }
}
* { box-sizing: border-box; }
html { scroll-behavior: smooth; scroll-padding-top: 24px; }
html, body { margin: 0; padding: 0; }
body { background: var(--bg); color: var(--text); font-family: -apple-system, BlinkMacSystemFont, "Inter", "Segoe UI", "SF Pro Text", system-ui, sans-serif; line-height: 1.7; font-size: 16px; font-feature-settings: "ss01","cv01","cv11"; -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale; text-rendering: optimizeLegibility; }
::selection { background: var(--accent-soft); color: var(--text); }
.page { max-width: 820px; margin: 0 auto; padding: 56px 32px 120px; }
header.hero { border-bottom: 1px solid var(--border); padding-bottom: 28px; margin-bottom: 40px; }
.eyebrow { color: var(--text-faint); font-size: 12px; font-weight: 600; letter-spacing: 0.12em; text-transform: uppercase; margin-bottom: 10px; }
h1 { font-size: 32px; line-height: 1.2; margin: 0 0 16px; font-weight: 750; letter-spacing: -0.015em; color: var(--text); }
h2 { font-size: 22px; line-height: 1.3; margin: 56px 0 16px; padding-bottom: 8px; border-bottom: 1px solid var(--border); font-weight: 700; letter-spacing: -0.01em; scroll-margin-top: 24px; }
h2 .anchor { opacity: 0; margin-left: 8px; color: var(--text-faint); font-weight: 400; text-decoration: none; transition: opacity 120ms; }
h2:hover .anchor { opacity: 1; }
h3 { font-size: 17px; margin: 28px 0 8px; font-weight: 650; letter-spacing: -0.005em; }
p { margin: 14px 0; }
ul, ol { margin: 14px 0; padding-left: 24px; }
li { margin: 6px 0; }
strong { font-weight: 650; color: var(--text); }
a { color: var(--accent-strong); text-decoration: none; border-bottom: 1px solid transparent; transition: border-color 120ms; }
a:hover { border-bottom-color: var(--accent-strong); }
hr { border: 0; border-top: 1px solid var(--border); margin: 40px 0; }
.callout { position: relative; border: 1px solid var(--border); border-left: 3px solid var(--accent-strong); background: var(--panel); padding: 16px 20px 16px 48px; border-radius: 8px; margin: 20px 0; box-shadow: var(--shadow-sm); }
.callout::before { content: ""; position: absolute; left: 18px; top: 18px; width: 18px; height: 18px; background-color: var(--accent-strong); -webkit-mask: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'><circle cx='8' cy='8' r='7' fill='none' stroke='currentColor' stroke-width='1.5'/><circle cx='8' cy='5' r='1' fill='currentColor'/><path d='M8 8v4' stroke='currentColor' stroke-width='1.5' stroke-linecap='round'/></svg>") center/contain no-repeat; mask: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'><circle cx='8' cy='8' r='7' fill='none' stroke='currentColor' stroke-width='1.5'/><circle cx='8' cy='5' r='1' fill='currentColor'/><path d='M8 8v4' stroke='currentColor' stroke-width='1.5' stroke-linecap='round'/></svg>") center/contain no-repeat; }
.callout.warn { border-left-color: var(--warn-border); background: var(--warn-soft); }
.callout.warn::before { background-color: var(--warn-border); -webkit-mask: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'><path d='M8 1.5L15 14H1L8 1.5z' fill='none' stroke='currentColor' stroke-width='1.5' stroke-linejoin='round'/><path d='M8 6.5v3' stroke='currentColor' stroke-width='1.5' stroke-linecap='round'/><circle cx='8' cy='12' r='0.8' fill='currentColor'/></svg>") center/contain no-repeat; mask: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'><path d='M8 1.5L15 14H1L8 1.5z' fill='none' stroke='currentColor' stroke-width='1.5' stroke-linejoin='round'/><path d='M8 6.5v3' stroke='currentColor' stroke-width='1.5' stroke-linecap='round'/><circle cx='8' cy='12' r='0.8' fill='currentColor'/></svg>") center/contain no-repeat; }
.callout-title { font-weight: 700; font-size: 12px; text-transform: uppercase; letter-spacing: 0.1em; color: var(--accent-strong); margin-bottom: 6px; }
.callout.warn .callout-title { color: var(--warn-text); }
.callout p:first-of-type { margin-top: 0; }
.callout p:last-child, .callout ul:last-child { margin-bottom: 0; }
code { font-family: ui-monospace, "JetBrains Mono", SFMono-Regular, "SF Mono", Menlo, Consolas, monospace; font-size: 0.875em; background: var(--code-bg); border: 1px solid var(--code-border); border-radius: 4px; padding: 1.5px 6px; font-feature-settings: "calt" 0, "liga" 0; }
.file-pill { display: inline-block; background: var(--panel-2); border: 1px solid var(--border); border-radius: 4px; padding: 1.5px 7px; font-family: ui-monospace, "JetBrains Mono", SFMono-Regular, "SF Mono", Menlo, Consolas, monospace; font-size: 13px; font-weight: 500; color: var(--text); white-space: nowrap; }
pre { position: relative; background: var(--code-bg); border: 1px solid var(--code-border); border-radius: 10px; padding: 16px 56px 16px 18px; overflow-x: auto; margin: 14px 0; box-shadow: var(--shadow-sm); line-height: 1.6; }
pre code { background: transparent; border: 0; padding: 0; font-size: 14px; line-height: 1.65; white-space: pre; color: var(--text); font-feature-settings: "calt" 0, "liga" 0; }
pre.value { padding: 12px 56px 12px 16px; }
pre.value code { font-size: 14px; font-weight: 500; }
.comment { color: var(--text-faint); font-style: italic; }
.copy-btn { position: absolute; top: 8px; right: 8px; width: 32px; height: 32px; border: 1px solid var(--border-strong); border-radius: 6px; background: var(--panel-2); color: var(--text-muted); cursor: pointer; display: inline-flex; align-items: center; justify-content: center; transition: all 140ms ease; padding: 0; opacity: 0.85; }
pre:hover .copy-btn { opacity: 1; }
.copy-btn:hover { color: var(--accent-strong); border-color: var(--accent-strong); background: var(--panel-hover); }
.copy-btn:active { transform: scale(0.94); }
.copy-btn:focus-visible { outline: 2px solid var(--accent-strong); outline-offset: 2px; }
.copy-btn.copied { color: var(--ok-text); border-color: var(--ok); background: var(--panel-2); }
.copy-btn svg { width: 15px; height: 15px; }
.copy-btn::after { content: attr(data-tip); position: absolute; bottom: calc(100% + 6px); right: 0; background: var(--text); color: var(--bg); font-size: 11px; font-weight: 600; padding: 4px 8px; border-radius: 4px; white-space: nowrap; opacity: 0; pointer-events: none; transform: translateY(2px); transition: opacity 140ms, transform 140ms; }
.copy-btn.copied::after { opacity: 1; transform: translateY(0); }
kbd { display: inline-block; background: var(--kbd-bg); border: 1px solid var(--border-strong); border-bottom-width: 2px; border-radius: 5px; padding: 1.5px 7px; font-family: ui-monospace, "JetBrains Mono", SFMono-Regular, Menlo, Consolas, monospace; font-size: 12px; font-weight: 600; line-height: 1.4; color: var(--text); box-shadow: var(--shadow-sm); }
ol.steps { counter-reset: step; list-style: none; padding: 0; margin: 20px 0; }
ol.steps > li { counter-increment: step; position: relative; padding: 16px 20px 16px 60px; margin: 10px 0; background: var(--panel); border: 1px solid var(--border); border-radius: 10px; transition: border-color 140ms, background 140ms; }
ol.steps > li:hover { border-color: var(--border-strong); background: var(--bg-elev); }
ol.steps > li::before { content: counter(step); position: absolute; left: 16px; top: 16px; width: 30px; height: 30px; border-radius: 50%; background: var(--accent-soft); color: var(--accent-strong); font-weight: 700; font-size: 14px; display: flex; align-items: center; justify-content: center; border: 1px solid var(--accent-strong); }
ol.steps ul { padding-left: 22px; margin: 8px 0; }
ol.steps li li { margin: 6px 0; }
ol.steps pre { margin: 10px 0 4px; }
.grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin: 14px 0; }
.grid-2 .card { background: var(--panel); border: 1px solid var(--border); border-radius: 10px; padding: 16px 18px; transition: border-color 140ms; }
.grid-2 .card:hover { border-color: var(--border-strong); }
.card-title { font-size: 11px; font-weight: 700; color: var(--text-faint); text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 8px; }
.badge { display: inline-block; font-size: 11px; font-weight: 700; letter-spacing: 0.08em; text-transform: uppercase; padding: 3px 9px; border-radius: 999px; border: 1px solid var(--border-strong); background: var(--panel-2); color: var(--text-muted); margin-right: 4px; }
.badge.ok { color: var(--ok-text); border-color: var(--ok); }
.badge.warn { color: var(--warn-text); border-color: var(--warn-border); background: var(--warn-soft); }
table { border-collapse: collapse; margin: 14px 0; width: 100%; font-size: 14px; }
table th, table td { border: 1px solid var(--border); padding: 10px 14px; text-align: left; }
table th { background: var(--panel); font-weight: 700; color: var(--text); }
table tr:nth-child(even) td { background: var(--panel); }
.back-to-top { position: fixed; bottom: 24px; right: 24px; width: 40px; height: 40px; border: 1px solid var(--border-strong); border-radius: 50%; background: var(--panel-2); color: var(--text-muted); cursor: pointer; display: inline-flex; align-items: center; justify-content: center; box-shadow: var(--shadow-md); opacity: 0; transform: translateY(8px); pointer-events: none; transition: opacity 200ms, transform 200ms, color 140ms, border-color 140ms; padding: 0; z-index: 50; }
.back-to-top.visible { opacity: 1; transform: translateY(0); pointer-events: auto; }
.back-to-top:hover { color: var(--accent-strong); border-color: var(--accent-strong); }
.back-to-top svg { width: 16px; height: 16px; }
.toc { position: fixed; top: 96px; left: calc(50vw + 410px + 40px); width: 220px; max-height: calc(100vh - 140px); overflow-y: auto; font-size: 13px; line-height: 1.5; padding-left: 18px; border-left: 1px solid var(--border); z-index: 40; scrollbar-width: thin; scrollbar-color: var(--border-strong) transparent; }
.toc::-webkit-scrollbar { width: 6px; }
.toc::-webkit-scrollbar-track { background: transparent; }
.toc::-webkit-scrollbar-thumb { background: var(--border-strong); border-radius: 3px; }
.toc-title { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.1em; color: var(--text-faint); margin: 0 0 12px; padding: 0; }
.toc nav ul { list-style: none; margin: 0; padding: 0; }
.toc nav li { margin: 0; padding: 0; }
.toc nav a { display: block; color: var(--text-muted); text-decoration: none; font-weight: 500; padding: 5px 0 5px 14px; margin-left: -15px; border-left: 2px solid transparent; transition: color 140ms ease, border-color 140ms ease; border-bottom: 0; }
.toc nav a:hover { color: var(--text); border-bottom: 0; }
.toc nav a.active { color: var(--accent-strong); border-left-color: var(--accent-strong); font-weight: 650; }
@media (max-width: 1180px) { .toc { display: none; } }
@media (max-width: 720px) { .page { padding: 32px 18px 80px; } h1 { font-size: 26px; } h2 { font-size: 19px; margin-top: 40px; } .grid-2 { grid-template-columns: 1fr; } .back-to-top { bottom: 16px; right: 16px; } }
@media (prefers-reduced-motion: reduce) { html { scroll-behavior: auto; } *, *::before, *::after { animation-duration: 0.01ms !important; transition-duration: 0.01ms !important; } }
```

### JavaScript (paste verbatim)

```javascript
(function () {
  const COPY_ICON = '<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.6"><rect x="4.5" y="4.5" width="8" height="9" rx="1.5"/><path d="M3.5 11.5V3.5a1 1 0 0 1 1-1h8"/></svg>';
  const CHECK_ICON = '<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M3 8.5l3.5 3.5L13 5"/></svg>';
  const ARROW_UP = '<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2"><path d="M8 13V3M3.5 7.5L8 3l4.5 4.5"/></svg>';

  document.querySelectorAll('pre').forEach(function (pre) {
    const btn = document.createElement('button');
    btn.className = 'copy-btn';
    btn.type = 'button';
    btn.setAttribute('aria-label', 'Copy to clipboard');
    btn.setAttribute('data-tip', 'Copy');
    btn.innerHTML = COPY_ICON;
    btn.addEventListener('click', function (e) {
      e.preventDefault();
      const code = pre.querySelector('code');
      const text = code ? code.innerText : pre.innerText;
      const done = function () {
        btn.classList.add('copied');
        btn.setAttribute('data-tip', 'Copied!');
        btn.innerHTML = CHECK_ICON;
        setTimeout(function () {
          btn.classList.remove('copied');
          btn.setAttribute('data-tip', 'Copy');
          btn.innerHTML = COPY_ICON;
        }, 1600);
      };
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(done).catch(function () { fallbackCopy(text); done(); });
      } else { fallbackCopy(text); done(); }
    });
    pre.appendChild(btn);
  });

  function fallbackCopy(text) {
    const ta = document.createElement('textarea');
    ta.value = text;
    ta.style.position = 'fixed';
    ta.style.opacity = '0';
    document.body.appendChild(ta);
    ta.select();
    try { document.execCommand('copy'); } catch (e) {}
    document.body.removeChild(ta);
  }

  const h2Nodes = Array.from(document.querySelectorAll('h2'));
  const tocItems = h2Nodes.map(function (h2) {
    if (!h2.id) {
      h2.id = h2.textContent.trim().toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
    }
    const text = h2.textContent.trim();
    const a = document.createElement('a');
    a.className = 'anchor';
    a.href = '#' + h2.id;
    a.setAttribute('aria-label', 'Link to section');
    a.textContent = '#';
    h2.appendChild(a);
    return { id: h2.id, text: text, el: h2 };
  });

  if (tocItems.length >= 2) {
    const aside = document.createElement('aside');
    aside.className = 'toc';
    aside.setAttribute('aria-label', 'Table of contents');
    const title = document.createElement('p');
    title.className = 'toc-title';
    title.textContent = 'In this article';
    aside.appendChild(title);
    const nav = document.createElement('nav');
    const ul = document.createElement('ul');
    const linkById = new Map();
    tocItems.forEach(function (item) {
      const li = document.createElement('li');
      const link = document.createElement('a');
      link.href = '#' + item.id;
      link.textContent = item.text;
      li.appendChild(link);
      ul.appendChild(li);
      linkById.set(item.id, link);
    });
    nav.appendChild(ul);
    aside.appendChild(nav);
    document.body.appendChild(aside);

    const setActive = function (id) {
      linkById.forEach(function (link, key) {
        link.classList.toggle('active', key === id);
      });
    };
    const updateActive = function () {
      const probe = window.scrollY + 120;
      let activeId = tocItems[0].id;
      for (let i = 0; i < tocItems.length; i++) {
        if (tocItems[i].el.offsetTop <= probe) activeId = tocItems[i].id;
        else break;
      }
      if (window.scrollY + window.innerHeight >= document.body.scrollHeight - 4) {
        activeId = tocItems[tocItems.length - 1].id;
      }
      setActive(activeId);
    };
    let tocTicking = false;
    window.addEventListener('scroll', function () {
      if (!tocTicking) {
        requestAnimationFrame(function () { updateActive(); tocTicking = false; });
        tocTicking = true;
      }
    }, { passive: true });
    updateActive();
  }

  const backBtn = document.createElement('button');
  backBtn.className = 'back-to-top';
  backBtn.type = 'button';
  backBtn.setAttribute('aria-label', 'Back to top');
  backBtn.innerHTML = ARROW_UP;
  backBtn.addEventListener('click', function () {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  });
  document.body.appendChild(backBtn);
  let ticking = false;
  window.addEventListener('scroll', function () {
    if (!ticking) {
      requestAnimationFrame(function () {
        backBtn.classList.toggle('visible', window.scrollY > 400);
        ticking = false;
      });
      ticking = true;
    }
  }, { passive: true });
})();
```

## Output Constraints

- Single self-contained `.html` file (no external assets)
- Must escape HTML entities (`<`, `>`, `&`, `"`) inside text content
- Inside `<pre><code>` blocks: escape `<` and `>` but preserve all whitespace and newlines verbatim
- Do NOT add language-specific syntax highlighting — copy buttons + monospace are enough
- Use `&mdash;` for em-dashes, `&rarr;` for right arrows in prose where the source uses `—` / `→`

## Done Criteria

- HTML opens in browser with no console errors
- All `<pre>` blocks have a working copy button (icon flips to green check + "Copied!" tooltip on click)
- All `<h2>` headings get auto-generated `id` slugs and a hover `#` anchor link
- Floating "back to top" button appears after scrolling past 400px
- Sticky right-side TOC ("In this article") auto-builds from H2 sections, highlights active section on scroll, and hides on viewports ≤ 1180px (or when the doc has < 2 H2s)
- Theme switches automatically with system dark/light preference
- Body text contrast meets WCAG AAA (≥7:1) in both modes
- Reduced-motion preference disables transitions/smooth-scroll
- No broken links to external CSS or JS

Begin: read the markdown, transform per the rules above, write the HTML file.
