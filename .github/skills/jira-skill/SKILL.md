---
name: jira-skill
description: Create, search, update, and link Jira user stories from natural language requirements via the Atlassian MCP Server. Use when the user asks to "create a Jira story", "draft a ticket", "raise an issue", "search Jira", "update a Jira ticket", "link a story to an epic", or mentions sprint planning, backlog grooming, or refining a user story. Drafts a structured six-section story (title, short description, why, work to complete, additional information, acceptance criteria), self-validates it, gets explicit user approval, then posts via the Atlassian MCP. Do NOT use this for posting comments or work logs — only for issue creation, edits, search, and linking.
---

# Jira Story Creator

Create, search, update, and link Jira user stories from natural language requirements via the Atlassian MCP Server.

## When to Use

Use this skill when:
- Creating Jira user stories from requirements, notes, or meeting actions
- Searching, updating, or linking Jira issues
- Sprint planning or backlog grooming

## Configuration

- **Jira Project:** Ask the user for the project key if not provided (e.g. `SCRUM`)
- **Issue Type:** Story
- **Posting method:** Atlassian MCP Server exclusively — no scripts, no credentials required

## Story Structure

Every story MUST have these six sections. See [story-template.md](references/story-template.md) for the full template and [good-story-examples.md](references/good-story-examples.md) for completed examples.

1. **Title** — Under 80 characters, action verb, used as the Jira summary only (not in the description body)
2. **Short Description** — 1-2 sentences after the title, no heading
3. **Why are we carrying this out?** — Business justification, link to epic
4. **Work to complete** — Actionable bullet points
5. **Additional Information** — Links, contacts, related work
6. **Acceptance Criteria** — 3-4 testable pass/fail bullet points. Never use "AC1", "AC2" numbering

## Formatting

Jira uses Wiki Markup, not Markdown. See [jira-formatting.md](references/jira-formatting.md) for the conversion reference. Convert the draft to Wiki Markup before posting via MCP.

## Workflow

Follow these steps in order. Never skip the review step.

```
Story Progress:
- [ ] Step 1: Draft the story
- [ ] Step 2: Validate the draft
- [ ] Step 3: Get user approval
- [ ] Step 4: Post to Jira via MCP
- [ ] Step 5: Confirm the issue URL
```

### Step 1: Draft

Gather requirements and present the full story draft inline in the conversation for the user to review.

### Step 2: Validate

Before presenting to the user, self-validate the draft:

- All six sections are present
- Title is under 80 characters with an action verb
- Acceptance criteria are testable pass/fail statements
- No title text is repeated inside the description body

If anything fails, fix the draft before presenting it.

### Step 3: Approve

Present the draft and ask: **"Does this look good? If so, provide the Epic key and I'll post it to Jira."**

Do NOT proceed until the user explicitly confirms.

### Step 4: Post

Use the Atlassian MCP tools to create the issue:

1. Call `createJiraIssue` with the story summary and Wiki Markup description
2. If the user provided an Epic key, call `jiraWrite` with `createIssueLink` to link it

### Step 5: Confirm

Share the Jira issue URL with the user.

## MCP Tools Reference

| Tool | Purpose |
|------|---------|
| `createJiraIssue` | Create a new issue |
| `editJiraIssue` | Update an existing issue |
| `getJiraIssue` | Retrieve issue details |
| `searchJiraIssuesUsingJql` | Search issues with JQL |
| `jiraWrite` (createIssueLink) | Link a story to an Epic |
| `getVisibleJiraProjects` | List available projects |

## Rules

- Always draft and validate before posting — never post directly
- Never add labels unless the user requests them
- Never include the title inside the description body
- Keep language clear for all stakeholders
- Each story should be completable in a single sprint
