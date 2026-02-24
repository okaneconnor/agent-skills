# Jira Story Creator - Agent Skill

An agent skill for GitHub Copilot that creates well-structured Jira user stories from natural language requirements. Combined with the Atlassian MCP Server, Copilot can search, create, update, and link Jira issues directly from VS Code.

## Overview

This skill gives Copilot a structured template, formatting rules, and reference examples so that every story it creates follows a consistent format with clear titles, business justification, actionable work items, and testable acceptance criteria.

The Atlassian MCP Server connects Copilot to your Jira board, so stories can be posted, searched, and managed without leaving your editor.

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

- VS Code with GitHub Copilot enabled
- Node.js v18+
- An Atlassian Cloud account with a Jira project

### 1. Clone the repository

Clone this repository and open it in VS Code. Copilot automatically picks up the skill from `.github/jira-skill/SKILL.md` when the repository is open.

### 2. Configure your Jira credentials

Copy the example environment file and fill in your values:

```bash
cp .github/jira-skill/scripts/.env.example .github/jira-skill/scripts/.env
```

Then edit `.github/jira-skill/scripts/.env` with your details:

```
JIRA_URL=https://your-domain.atlassian.net
JIRA_PROJECT=YOUR_PROJECT_KEY
JIRA_API_EMAIL=your-email@example.com
JIRA_API_TOKEN=your-api-token
```

The script reads this file automatically. The `.env` file is gitignored so your credentials are never committed.

To create an API token, go to [https://id.atlassian.com/manage-profile/security/api-tokens](https://id.atlassian.com/manage-profile/security/api-tokens).

### 3. Add the Atlassian MCP Server

Create a file called `.vscode/mcp.json` in the project root:

```json
{
  "servers": {
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

This runs `mcp-remote` as a local proxy that handles OAuth 2.1 authentication with Atlassian's cloud endpoint. No API tokens or credentials need to be stored.

### 4. Authenticate

1. Open `.vscode/mcp.json` in VS Code
2. Click the **Start** button that appears above the server configuration
3. A browser window opens — sign in with your Atlassian account and grant access
4. Once complete, the MCP server is connected

### 5. Verify everything is working

1. Open Copilot Chat (`Ctrl+Shift+I`)
2. Switch to **Agent** mode
3. Click the **tools icon** and confirm the Atlassian tools are listed
4. Ask Copilot: *"What epics exist in my Jira project?"* to test the connection

## How to Use It

With the skill loaded and the MCP server connected, open Copilot Chat in **Agent** mode and describe what you need.

### Creating a story

> *"Create a Jira story for adding retry logic to the payment service"*

> *"Draft a story for setting up PostgreSQL connection pool alerting, link it to epic SCRUM-5"*

Copilot will draft a story using the skill's template, present it for your approval, and then post it to Jira.

### Searching your board

> *"Find all open epics in project SCRUM"*

> *"What stories are in the current sprint?"*

### Updating issues

> *"Move SCRUM-15 to In Progress"*

> *"Link SCRUM-20 to epic SCRUM-5"*

## Important Notes

- **Permissions** — The MCP server respects your existing Jira permissions. You will only see projects and issues you have access to.
- **First-time authentication** — The first user on your Atlassian site to complete the OAuth flow must have Jira access.
- **Local agent only** — The Atlassian MCP server works in VS Code's local Copilot Chat agent mode. The web-based Copilot Coding Agent does not currently support OAuth-based MCP servers.
- **No API tokens needed for MCP** — OAuth handles authentication via browser login. The CLI fallback script reads credentials from the `.env` file.

## References

- [Atlassian MCP Server](https://github.com/atlassian/atlassian-mcp-server)
- [VS Code MCP Server Documentation](https://code.visualstudio.com/docs/copilot/customization/mcp-servers)
- [GitHub Copilot MCP Documentation](https://docs.github.com/copilot/customizing-copilot/using-model-context-protocol/extending-copilot-chat-with-mcp)
- [Agent Skills Specification](https://agentskills.io/specification)
