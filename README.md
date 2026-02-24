# Agent Skills

A collection of agent skills for AI coding assistants. Each skill is available for both GitHub Copilot and Claude Code — pick the directory that matches your tool and follow the guide inside.

## Available Skills

| Skill | Description | Copilot | Claude Code |
|-------|-------------|---------|-------------|
| **Jira Story Creator** | Create, search, update, and link Jira user stories from natural language | [Guide](.github/jira-skill/ReadMe.md) | [Guide](.claude/skills/jira-skill/ReadMe.md) |

## How Skills Are Organised

Each skill lives in two locations so both tools can discover it automatically:

- **`.github/<skill-name>/`** — GitHub Copilot picks up skills from this directory
- **`.claude/skills/<skill-name>/`** — Claude Code picks up skills from this directory

Both copies contain the same files. Navigate to the directory for your tool and follow the ReadMe inside.

## Quick Start

1. Clone this repository
2. Find the skill you want in the table above
3. Click the guide link for your tool (Copilot or Claude Code)
4. Follow the setup instructions in that ReadMe

## References

- [Agent Skills Specification](https://agentskills.io/specification)
- [Atlassian MCP Server](https://github.com/atlassian/atlassian-mcp-server)
