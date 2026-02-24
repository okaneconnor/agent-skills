---
name: jira-skill
description: Creates well-structured Jira user stories from natural language requirements and posts them to Atlassian Cloud Jira. Searches, updates, and links Jira issues via the Atlassian MCP Server. Activates when the user mentions Jira stories, tickets, user stories, epics, sprint planning, backlog grooming, or wants to convert notes, requirements, or meeting actions into Jira issues.
compatibility: Requires Claude Code CLI, Node.js v18+, and an Atlassian Cloud account. Uses the Atlassian MCP Server for Jira integration.
metadata:
  author: connorokane
  version: "1.0"
---

# Jira Story Creator

## Configuration

The Jira instance and default project are read from environment variables:

- **`JIRA_URL`** — Atlassian Cloud instance URL (e.g. `https://your-domain.atlassian.net`)
- **`JIRA_PROJECT`** — Default project key (e.g. `SCRUM`)
- **Issue Type:** Story

## Story Structure

Every story MUST have these six sections. See [story-template.md](references/story-template.md) for the full template and [good-story-examples.md](references/good-story-examples.md) for completed examples.

1. **Title** — Under 80 characters, action verb, used as the Jira summary only (not in the description body)
2. **Short Description** — 1-2 sentences after the title, no heading
3. **Why are we carrying this out?** — Business justification, link to epic
4. **Work to complete** — Actionable bullet points
5. **Additional Information** — Links, contacts, related work
6. **Acceptance Criteria** — 3-4 testable pass/fail bullet points. Never use "AC1", "AC2" numbering

## Formatting

Jira uses Wiki Markup, not Markdown. See [jira-formatting.md](references/jira-formatting.md) for the conversion reference. The `post-to-jira.py` script converts Markdown drafts automatically.

## Workflow

Follow these steps in order. Never skip the review step.

```
Story Progress:
- [ ] Step 1: Draft the story
- [ ] Step 2: Validate the draft
- [ ] Step 3: Get user approval
- [ ] Step 4: Post to Jira
- [ ] Step 5: Confirm the issue URL
```

### Step 1: Draft

Gather requirements and create a Markdown file. Save to `/tmp/draft_<name>.md` — never inside the repository.

### Step 2: Validate

Run the dry-run to preview the converted payload:

```bash
python3 .claude/skills/jira-skill/scripts/post-to-jira.py /tmp/draft_<name>.md --dry-run
```

Check the output:
- All six sections are present
- Title is under 80 characters with an action verb
- Acceptance criteria are testable pass/fail statements
- No raw Markdown remains in the Wiki Markup output

If anything fails, fix the draft and run `--dry-run` again.

### Step 3: Approve

Present the dry-run output and ask: **"Does this look good? If so, provide the Epic key and I'll post it to Jira."**

Do NOT proceed until the user explicitly confirms.

### Step 4: Post

**Via MCP** (preferred):

Use `atlassian:jira_create_issue` to create the story. Use `atlassian:jira_link_issues` to link it to an Epic if provided.

**Via CLI** (fallback):

```bash
python3 .claude/skills/jira-skill/scripts/post-to-jira.py /tmp/draft_<name>.md --epic <EPIC-KEY>
```

The script reads credentials from `.claude/skills/jira-skill/scripts/.env` (copy from `.env.example`). Requires `pip install requests`.

### Step 5: Confirm

Share the Jira issue URL with the user.

## MCP Tools Reference

| Tool | Purpose |
|------|---------|
| `atlassian:jira_create_issue` | Create a new issue |
| `atlassian:jira_edit_issue` | Update an existing issue |
| `atlassian:jira_get_issue` | Retrieve issue details |
| `atlassian:jira_search` | Search issues with JQL |
| `atlassian:jira_link_issues` | Link a story to an Epic |
| `atlassian:jira_list_projects` | List available projects |

## Rules

- Always draft and validate before posting — never post directly
- Never add labels unless the user requests them
- Never include the title inside the description body
- Keep language clear for all stakeholders
- Each story should be completable in a single sprint
