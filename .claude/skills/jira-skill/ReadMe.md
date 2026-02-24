# Jira Story Creator - Agent Skill

An agent skill for Claude Code that creates well-structured Jira user stories from natural language requirements. Combined with the Atlassian MCP Server, Claude can search, create, update, and link Jira issues directly from the terminal.

## Overview

This skill gives Claude a structured template, formatting rules, and reference examples so that every story it creates follows a consistent format with clear titles, business justification, actionable work items, and testable acceptance criteria.

The Atlassian MCP Server connects Claude to your Jira board, so stories can be posted, searched, and managed without leaving your terminal.

### What is Included

| File | Purpose |
|------|---------|
| `SKILL.md` | Skill definition — story structure, workflow, and MCP tool references |
| `references/story-template.md` | Blank template with per-section guidelines |
| `references/good-story-examples.md` | Four completed example stories across different domains |
| `references/jira-formatting.md` | Markdown to Jira Wiki Markup conversion reference |
| `scripts/post-to-jira.py` | CLI script for dry-run previews and fallback posting |
| `scripts/.env.example` | Template for Jira credentials — copy to `.env` and fill in |

## Getting Started

### Prerequisites

- Claude Code CLI installed
- Node.js v18+
- An Atlassian Cloud account with a Jira project

### 1. Clone the repository

Clone this repository. Claude Code automatically picks up the skill from `.claude/skills/jira-skill/SKILL.md` when you run it from the project root.

### 2. Configure your Jira credentials

Copy the example environment file and fill in your values:

```bash
cp .claude/skills/jira-skill/scripts/.env.example .claude/skills/jira-skill/scripts/.env
```

Then edit `.claude/skills/jira-skill/scripts/.env` with your details:

```
JIRA_URL=https://your-domain.atlassian.net
JIRA_PROJECT=YOUR_PROJECT_KEY
JIRA_API_EMAIL=your-email@example.com
JIRA_API_TOKEN=your-api-token
```

The script reads this file automatically. The `.env` file is gitignored so your credentials are never committed.

To create an API token, go to [https://id.atlassian.com/manage-profile/security/api-tokens](https://id.atlassian.com/manage-profile/security/api-tokens).

### 3. Add the Atlassian MCP Server

Create a file called `.mcp.json` in the project root:

```json
{
  "mcpServers": {
    "atlassian": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "https://mcp.atlassian.com/v1/mcp"
      ]
    }
  }
}
```

This runs `mcp-remote` as a local proxy that handles OAuth 2.1 authentication with Atlassian's cloud endpoint. No API tokens or credentials need to be stored for the MCP connection.

### 4. Authenticate

1. Start Claude Code from the project root
2. Claude will detect the MCP server configuration and start `mcp-remote`
3. A browser window opens — sign in with your Atlassian account and grant access
4. Once complete, the MCP server is connected

### 5. Verify everything is working

Ask Claude: *"What epics exist in my Jira project?"* to test the connection.

## How to Use It

With the skill loaded and the MCP server connected, describe what you need in Claude Code.

### Creating a story

> *"Create a Jira story for adding retry logic to the payment service"*

> *"Draft a story for setting up PostgreSQL connection pool alerting, link it to epic SCRUM-5"*

Claude will draft a story using the skill's template, present it for your approval, and then post it to Jira.

### Searching your board

> *"Find all open epics in project SCRUM"*

> *"What stories are in the current sprint?"*

### Updating issues

> *"Move SCRUM-15 to In Progress"*

> *"Link SCRUM-20 to epic SCRUM-5"*

## Important Notes

- **Permissions** — The MCP server respects your existing Jira permissions. You will only see projects and issues you have access to.
- **First-time authentication** — The first user on your Atlassian site to complete the OAuth flow must have Jira access.
- **No API tokens needed for MCP** — OAuth handles authentication via browser login. The CLI fallback script reads credentials from the `.env` file.

## References

- [Atlassian MCP Server](https://github.com/atlassian/atlassian-mcp-server)
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Agent Skills Specification](https://agentskills.io/specification)
