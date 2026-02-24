# Agent Skills

A collection of agent skills for AI coding assistants. Each skill is available for both GitHub Copilot and Claude Code — pick the one that matches your tool.

## Available Skills

### Jira Story Creator

Creates well-structured Jira user stories from natural language requirements. Searches, creates, updates, and links Jira issues via the Atlassian MCP Server.

| Tool | Skill Location | Guide |
|------|---------------|-------|
| GitHub Copilot | `.github/jira-skill/` | [ReadMe](.github/jira-skill/ReadMe.md) |
| Claude Code | `.claude/skills/jira-skill/` | [ReadMe](.claude/skills/jira-skill/ReadMe.md) |

Both versions contain the same skill — identical templates, examples, formatting reference, and Python script. The only difference is the directory structure each tool expects.

## Quick Start

1. Clone this repository
2. Navigate to the skill directory for your tool (see table above)
3. Follow the ReadMe in that directory to configure credentials and the MCP server
4. Start creating Jira stories from natural language

## How It Works

Each skill includes:

- **SKILL.md** — The skill definition that your AI assistant loads automatically
- **Reference files** — Story template, example stories, and Jira formatting guide
- **Python script** — CLI tool for dry-run previews and fallback posting via the Jira REST API
- **MCP server config** — Connects your assistant to Jira via the Atlassian MCP Server for direct board access

## References

- [Atlassian MCP Server](https://github.com/atlassian/atlassian-mcp-server)
- [Agent Skills Specification](https://agentskills.io/specification)
