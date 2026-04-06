# Agent Skills

A collection of agent skills for AI coding assistants — Jira story creation and codebase architecture diagram generation via Excalidraw.

Packaged with [APM (Agent Package Manager)](https://github.com/microsoft/apm) for easy installation across tools.

## Install

```bash
apm install okaneconnor/agent-skills
```

## What's Included

| Primitive | File | Purpose |
|-----------|------|---------|
| **Skill** | `.apm/skills/jira-skill/SKILL.md` | Create, search, update, and link Jira user stories from natural language |
| **Skill** | `.apm/skills/excalidraw-diagram/SKILL.md` | Analyse a software or infrastructure codebase and draw an accurate, cited Excalidraw diagram (architecture, auth flow, security, data flow, deployment topology, sequence, module dependency) |

### Jira Skill Reference Files

The Jira skill includes reference files in `.apm/skills/jira-skill/references/`:

| File | Purpose |
|------|---------|
| `story-template.md` | Blank template with per-section guidelines |
| `good-story-examples.md` | Four completed example stories across different domains |
| `jira-formatting.md` | Markdown to Jira Wiki Markup conversion reference |

### Excalidraw Diagram Reference Files

The Excalidraw diagram skill includes reference files in `.apm/skills/excalidraw-diagram/references/`:

| File | Purpose |
|------|---------|
| `analysis-workflow.md` | Citation-first codebase exploration steps, with per-diagram-type discovery checklists |
| `diagram-types.md` | Layout blueprints for the 7 supported diagram types (architecture, auth flow, security, data flow, topology, sequence, module dependency) |
| `excalidraw-style-guide.md` | Opinionated colour/shape/arrow vocabulary, camera planning, and streaming order on top of the Excalidraw MCP `read_me` reference |
| `accuracy-checklist.md` | Three-pass pre-render validation (completeness, correctness, drawability) used to guarantee every shape and arrow is cited from the code |

## MCP Server Setup

### Atlassian MCP Server (Jira Skill)

This package uses the [Atlassian MCP Server](https://github.com/atlassian/atlassian-mcp-server) for Jira integration.

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

### Excalidraw MCP Server (Codebase Diagram Skill)

The codebase diagram skill uses the [Excalidraw MCP Server](https://mcp.excalidraw.com) to render diagrams inline and publish them to excalidraw.com.

**Claude Code** — add to `.mcp.json`:
```json
{
  "mcpServers": {
    "excalidraw": {
      "type": "http",
      "url": "https://mcp.excalidraw.com"
    }
  }
}
```

**GitHub Copilot (VS Code)** — already wired up in this repo's `.vscode/mcp.json`. To add it elsewhere:
```json
{
  "servers": {
    "excalidraw": {
      "type": "http",
      "url": "https://mcp.excalidraw.com"
    }
  }
}
```

## Adding New Skills

1. Create a directory under `.apm/skills/<skill-name>/`
2. Add a `SKILL.md` describing what the skill does, when to use it, and how it works
3. Place any reference files in a `references/` subdirectory
4. Update this README to list the new skill

## Learn More

- [APM Documentation](https://github.com/microsoft/apm)
- [Atlassian MCP Server](https://github.com/atlassian/atlassian-mcp-server)
- [Excalidraw](https://excalidraw.com)
- [Agent Skills Specification](https://agentskills.io/specification)
