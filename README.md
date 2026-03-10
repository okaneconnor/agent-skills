# Agent Skills

A collection of agent skills for AI coding assistants — Jira story creation, search, and management via the Atlassian MCP Server.

Packaged with [APM (Agent Package Manager)](https://github.com/microsoft/apm) for easy installation across tools.

## Install

```bash
apm install connorokane/agent-skills
```

## What's Included

| Primitive | File | Purpose |
|-----------|------|---------|
| **Skill** | `.apm/skills/jira-skill/SKILL.md` | Create, search, update, and link Jira user stories from natural language |

### Reference Files

The Jira skill includes reference files in `.apm/skills/jira-skill/references/`:

| File | Purpose |
|------|---------|
| `story-template.md` | Blank template with per-section guidelines |
| `good-story-examples.md` | Four completed example stories across different domains |
| `jira-formatting.md` | Markdown to Jira Wiki Markup conversion reference |

## MCP Server Setup

This package uses the [Atlassian MCP Server](https://github.com/atlassian/atlassian-mcp-server) for Jira integration. After installing, configure the MCP server for your tool:

**Claude Code** — add to `.mcp.json`:
```json
{
  "mcpServers": {
    "atlassian": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://mcp.atlassian.com/v1/mcp"]
    }
  }
}
```

**GitHub Copilot (VS Code)** — add to `.vscode/mcp.json`:
```json
{
  "servers": {
    "atlassian": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://mcp.atlassian.com/v1/mcp"]
    }
  }
}
```

Start your tool and a browser window will open for OAuth authentication. No API tokens or credentials need to be stored.

## Manual Setup (without APM)

Copy the skill files to the location your tool expects:

- **Claude Code** — copy `.apm/skills/jira-skill/` to `.claude/skills/jira-skill/`
- **GitHub Copilot** — copy `.apm/skills/jira-skill/` to `.github/jira-skill/`

## Adding New Skills

1. Create a directory under `.apm/skills/<skill-name>/`
2. Add a `SKILL.md` describing what the skill does, when to use it, and how it works
3. Place any reference files in a `references/` subdirectory
4. Update this README to list the new skill

## Learn More

- [APM Documentation](https://github.com/microsoft/apm)
- [Atlassian MCP Server](https://github.com/atlassian/atlassian-mcp-server)
- [Agent Skills Specification](https://agentskills.io/specification)
