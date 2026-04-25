# skills

My personal agent skills.

## Skills

| Skill | Description |
|-------|-------------|
| [excaliclaw](excaliclaw/SKILL.md) | Create reliable Excalidraw diagrams via the Excalidraw MCP, with export-safe labels, Excalifont text, and clear system-diagram structure. |

## Usage

### OpenClaw

Install a skill via ClawHub:

```bash
openclaw skills install excaliclaw
```

Or directly from this repo:

```bash
npx skills add nickytonline/skills --skill excaliclaw
```

Then invoke it in a prompt, e.g. `architecture diagram of my API`.

### Claude Code

Skills are invoked with a `/` prefix, e.g. `/excaliclaw architecture of my API`.
