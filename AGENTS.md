# Skills

This repo contains personal Claude Code skills. Each skill lives in its own subdirectory with a `SKILL.md` that defines its behavior.

## Available skills

### browser-testing

**OpenClaw:** triggers automatically for frontend browser testing and debugging
**Claude Code:** `/browser-testing [page or behavior to verify]`

Tests web interfaces without flooding the model context. Key behaviors:

- Uses Playwright MCP for navigation, interaction, responsive checks, accessibility state, and focused screenshots.
- Escalates to Chrome DevTools only for network internals, runtime state, computed styles, console diagnostics, or performance traces.
- Forbids full DOM and HTML dumps, repeated broad snapshots, and unnecessary screenshots.
- Requires narrow, filtered DevTools output and returns to Playwright for final user-flow verification.

### clip-to-social

**OpenClaw:** triggers automatically when turning video transcripts or clip excerpts into social posts
**Claude Code:** `/clip-to-social [transcript or clip excerpt]`

Creates ready-to-paste copy for X/Twitter, LinkedIn, YouTube Shorts, and TikTok. Key behaviors:

- Extracts one strong idea instead of summarizing the transcript chronologically.
- Caps X/Twitter posts at 280 characters and never adds hashtags.
- Keeps LinkedIn posts to at most two paragraphs, reuses the X copy when it already works, and includes relevant hashtags by default.
- Produces a concise YouTube Short title ending in `#shorts` and a description with relevant hashtags.
- Produces a concise TikTok caption with relevant hashtags.
- Preserves uncertainty and avoids hardening rough transcript estimates into factual claims.

### excaliclaw

**OpenClaw:** triggers automatically on diagram requests, e.g. `architecture diagram of my API`
**Claude Code:** `/excaliclaw [diagram topic]`

Creates Excalidraw diagrams via the Excalidraw MCP that survive OpenClaw rendering and Excalidraw export. Key behaviors:

- Verifies MCP availability before starting; asks before installing if missing.
- Uses explicit shape + text element pairs instead of the flaky `label` shortcut.
- Binds box labels via `containerId`/`boundElements` and arrows via `startBinding`/`endBinding`.
- Sets `fontFamily: 1` (Excalifont) on all text.
- Strips MCP-only pseudo-elements (`cameraUpdate`, etc.) before exporting.
- Exports a full scene object (`type`, `version`, `source`, `elements`, `appState`, `files`), not a raw element array.

See [`excaliclaw/SKILL.md`](excaliclaw/SKILL.md) for the full spec including element recipes, routing patterns, and fallback rules.

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org/) for all commit messages, e.g. `feat(excaliclaw): add arrow routing recipes` or `fix(excaliclaw): strip cameraUpdate before export`.

## Adding a skill

1. Create a subdirectory: `mkdir <skill-name>`
2. Add a `SKILL.md` with the required frontmatter:

```markdown
---
name: <skill-name>
description: <one-line description used for trigger matching>
user-invocable: true
argument-hint: "[optional hint]"
---
```

3. Write the skill body — rules, recipes, and fallbacks the model should follow when the skill fires.
4. Update the table in `README.md` and the skills list in this file.
