# skills

My personal agent skills.

## Skills

| Skill | Description |
|-------|-------------|
| [clip-to-social](clip-to-social/SKILL.md) | Turn video clip transcripts into concise X/Twitter, LinkedIn, YouTube Short, and TikTok promotional copy. |
| [excaliclaw](excaliclaw/SKILL.md) | Create reliable Excalidraw diagrams via the Excalidraw MCP, with export-safe labels, Excalifont text, and clear system-diagram structure. |
| [mergiraf](mergiraf/SKILL.md) | Resolve Git conflicts with Mergiraf as a deterministic first pass, then use agent reasoning only for conflicts that remain. |

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

Skills are invoked with a `/` prefix, e.g. `/excaliclaw architecture of my API` or `/clip-to-social [transcript]`.
