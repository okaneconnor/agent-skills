# Story Template

Use this template when creating new Jira story drafts. Save as `draft_<descriptive-name>.md`.

---

```
# Jira Story Draft - [Story Title]

## Title
[Clear, descriptive title - used as Jira summary field]

[Short description paragraph - no heading needed. Brief overview of what this story covers and why it matters.]

## Why are we carrying this out?

[Business justification. Link to initiative/epic goals. Explain the impact if this work is not done.]

## Work to complete

* [Actionable step 1]
* [Actionable step 2]
* [Actionable step 3]
* [Actionable step 4]

## Additional Information

**Links:**
* [Relevant documentation or repo](URL)
* [Related design docs or RFCs](URL)

**Points of Contact:**
* [Team/Person] - for [area of expertise]

**Related Work:**
* [Reference to similar past stories if applicable]

## Acceptance Criteria

Must be met to move this story into review:

* [Clear, testable criterion 1]
* [Clear, testable criterion 2]
* [Clear, testable criterion 3]
```

---

## Guidelines for Each Section

### Title
- Keep under 80 characters
- Be specific: "Implement rate limiting for public API endpoints" not "Update API"
- Use action verbs: Create, Update, Migrate, Configure, Remove, Investigate

### Short Description
- 1-2 sentences maximum
- Should answer: "What are we doing and why?"

### Why are we carrying this out?
- Connect to the broader initiative or epic
- Explain the risk or gap this addresses
- Keep it understandable for non-technical stakeholders

### Work to complete
- Each bullet should be a distinct, actionable task
- Not too granular (avoid "open VS Code") and not too vague (avoid "do the thing")
- An engineer should be able to read this and know what to do

### Acceptance Criteria
- 3-4 items maximum
- Each must be independently testable (pass/fail)
- Focus on outcomes, not implementation details
- Good example: "Rate limiting returns HTTP 429 with Retry-After header when threshold is exceeded"
- Bad example: "Run the script and check the logs"
