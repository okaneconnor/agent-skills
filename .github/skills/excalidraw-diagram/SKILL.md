---
name: excalidraw-diagram
description: Analyse a software or infrastructure codebase and produce a detailed, accurate Excalidraw diagram of its architecture, auth flow, security model, deployment topology, data flow, sequence flow, or module dependencies. Use when the user asks to "draw an architecture diagram of this repo", "show me how auth works", "diagram the security model", "visualise the data flow", "create an Excalidraw of the codebase", or points at a repo and wants a cited, accurate visual. Builds a citation-first model where every shape and arrow traces to a `file:line`, gets explicit approval, then renders via the Excalidraw MCP Server (https://mcp.excalidraw.com) and exports to a shareable URL. Do NOT use for speculative/aspirational architecture, single-file UML class diagrams, or Mermaid/Draw.io output.
---

# Codebase Architecture Diagrammer

Analyse a software or infrastructure codebase and produce a detailed, accurate Excalidraw diagram of its architecture, auth flow, security model, deployment topology, data flow, or component interactions. Diagrams are rendered through the Excalidraw MCP Server.

## When to Use

Use this skill when:

- The user points at a repo and asks for an architecture or infrastructure diagram
- The user wants to understand auth flow, security boundaries, network topology, or data flow in an unfamiliar codebase
- An onboarding doc, RFC, or design review needs a visual that mirrors what the code actually does (not what it was supposed to do)
- The user wants to compare "what the code says" against "what the docs say"
- The user explicitly asks for an Excalidraw diagram

Do **not** use this skill when:

- The user asks for a UML class diagram of a single file (use a code reader instead)
- The user wants speculative or aspirational architecture (this skill diagrams what exists, not what should exist)
- The user wants a Mermaid / draw.io / Lucid diagram — point them at the relevant tool

## Configuration

- **Source repo:** Always work from a local checkout. If the user references a remote repo, ask them to clone it and provide the absolute path.
- **Diagram tool:** Excalidraw MCP Server exclusively — never hand-roll an SVG, ASCII art, or Mermaid as a substitute.
- **Output:** An animated Excalidraw render in the conversation, plus an `excalidraw.com` shareable URL on request.
- **Accuracy bar:** Every component, edge, and label must trace to a concrete file:line in the repo. See [accuracy-checklist.md](references/accuracy-checklist.md).

## Diagram Types

Pick a type up front — different types have different layouts and different evidence requirements. See [diagram-types.md](references/diagram-types.md) for full layout blueprints.

| Type | When to use | What to capture |
|------|-------------|-----------------|
| **Architecture overview** | "Give me the big picture" | Top-level services, data stores, external dependencies, runtime hosts |
| **Auth flow** | "How does login work?" | Actors (user, client, IdP, API), tokens, redirect URIs, session storage |
| **Security model** | "Show me the trust boundaries" | Network segments, secrets, IAM/RBAC, encryption boundaries, ingress points |
| **Data flow** | "How does data move through this?" | Producers, consumers, queues/topics, schemas, storage hops |
| **Deployment topology** | "Where does this run?" | Environments, regions, networks, clusters, scaling units |
| **Sequence flow** | "Walk me through a request" | Time-ordered messages between actors with payloads |
| **Module dependency** | "How are the packages wired?" | Internal modules, public APIs, dependency direction |

## Workflow

Follow these steps in order. Never skip the validation or approval steps **unless the user has opted into Quick Mode** (see below).

```
Diagram Progress:
- [ ] Step 1: Scope the diagram
- [ ] Step 2: Discover the codebase
- [ ] Step 3: Build a cited model
- [ ] Step 4: Self-validate against the accuracy checklist
- [ ] Step 5: Get user approval on the model
- [ ] Step 5b: Lay out coordinates on a grid using the spacing constants
- [ ] Step 6: Render in Excalidraw
- [ ] Step 7: Export and share
```

### Quick Mode

For exploratory or low-stakes diagrams the user can opt out of the cited-model approval gate. **Trigger phrases:** "quick mode", "just draw it", "rough sketch", "exploratory", "skip the approval", "no need to validate".

In Quick Mode:

- Skip Steps 4 and 5 (self-validation and user approval)
- **Still do Step 5b** (grid layout with spacing constants — spacing is non-negotiable)
- **Still do Pass 4** of the accuracy checklist (spacing audit)
- The cited model becomes optional but recommended — it makes iteration cheaper
- Tell the user up-front: "Quick mode — I'll draw without the approval gate. Spacing rules still apply."

Use Quick Mode when the user is exploring an idea, sketching a concept, or doesn't yet know what they want. Never use it for documentation that will be shared, security reviews, or anything that needs to be accurate to a real codebase.

### Step 1: Scope

Confirm with the user:

1. **Which repo** (absolute path)
2. **Which diagram type** from the table above (offer the list if they don't pick)
3. **Focus area** if any (e.g. "just the auth subsystem", "just the staging environment")
4. **Audience** — onboarding engineer, security reviewer, architect, etc. — this drives detail level

If anything is ambiguous, ask before reading code. Diagramming the wrong thing is the most expensive mistake.

### Step 2: Discover

Systematically explore the repo. Follow [analysis-workflow.md](references/analysis-workflow.md) for the per-diagram-type checklist. At minimum:

- Read `README.md`, `ARCHITECTURE.md`, `docs/`, top-level config files
- Identify the language / framework / IaC tool (Terraform, Bicep, Kubernetes, Docker Compose, etc.)
- Find entry points (`main.*`, `app.*`, `index.*`, route definitions, handler registrations)
- Find infrastructure manifests (`*.tf`, `*.bicep`, `*.yaml` under `k8s/` or `helm/`, `Dockerfile`, `docker-compose.yml`)
- Find auth/security code by grepping for `oauth`, `jwt`, `session`, `auth`, `iam`, `role`, `policy`, `secret`
- Use the Explore subagent for codebases over ~50 files to avoid burning context

**Never** invent components. If you cannot find something in the code, it does not go in the diagram.

### Step 3: Build a Cited Model

Before drawing anything, write a plain-text model of the diagram inline in the conversation. The model has three sections:

```
## Components
- <name> — <one line> — <file:line>
- ...

## Edges
- <from> -> <to> : <label> — <file:line>
- ...

## Notes / Trust boundaries
- <name> — <file:line>
```

Every line must end with a `file:line` citation. No citation = no element. This is the contract that makes the diagram accurate.

### Step 4: Self-Validate

Run through [accuracy-checklist.md](references/accuracy-checklist.md). At minimum:

- Every component has a citation
- Every edge has a citation
- Nothing is in the model that is not in the code
- Nothing visible in the code that is critical to the diagram type is missing
- The diagram type matches the user's request

If anything fails, fix the model before showing the user.

### Step 5: Approve

Present the cited model and ask: **"Does this match the architecture you wanted? Reply 'render' to draw it, or tell me what to add, remove, or rename."**

Do NOT call `create_view` until the user explicitly confirms. Edits at this stage cost a few tokens; edits after rendering cost a full re-draw.

### Step 5b: Lay out coordinates on a grid

**Before writing any element JSON**, lay the diagram out on a coordinate grid using the spacing constants from [`excalidraw-style-guide.md`](references/excalidraw-style-guide.md#spacing-constants--hard-rules). Concretely:

1. Pick the camera size from the camera plan table for your diagram type.
2. Subtract `MARGIN_CANVAS` (60px) from each edge to get your drawable area.
3. Compute row anchors using `GAP_LAYER` (140px) for layered diagrams or `GAP_SHAPE_V` (100px) for grids.
4. Compute column anchors using `GAP_SHAPE_H` (80px) for adjacent shapes or `GAP_ACTOR_COL` (220px) for sequence-diagram actors.
5. **Write the anchors down** before any element JSON. The blueprints in `diagram-types.md` show worked spacing budgets you can copy.
6. If the layout doesn't fit at the spacing constants, use a **bigger camera** (Camera L → XL → XXL, or use the Landscape recipe). Never break a constant to fit.

This step is non-negotiable. Diagrams that skip the grid step end up cramped, and "more spacing please" iterations become 80-element manual rewrites instead of one-line constant bumps.

### Step 6: Render

Use the Excalidraw MCP Server to draw the approved model.

1. **Call `read_me` first** if you have not seen the Excalidraw element format in this conversation. It returns the colour palette, element schema, camera rules, and worked examples. Do not call it twice.
2. **Plan the layout** using the patterns in [diagram-types.md](references/diagram-types.md) and the styling rules in [excalidraw-style-guide.md](references/excalidraw-style-guide.md). You should already have grid coordinates from Step 5b.
3. **Run Pass 4 of the accuracy checklist (spacing audit)** against your computed coordinates before emitting any elements. If any constant is violated, fix it (bump the constant, use a bigger camera, or apply the Landscape recipe) before proceeding.
4. **Use standalone text elements only** — never the inline `label:` shortcut on shapes. The shortcut renders fine in `create_view` but produces empty boxes when exported. See the format divergence section in `excalidraw-style-guide.md`.
5. **Call `create_view`** with the elements array. Stream elements progressively (background → shape → text label → arrows → arrow text labels → next shape) so the draw-on animation is coherent.
6. Use **`cameraUpdate`** generously to pan and zoom the user's attention through the diagram as it builds — this is the single biggest readability lever.
7. Save the returned `checkpointId` so you can iterate without re-sending the whole diagram.

### Step 7: Export

Once the user is happy:

1. Run the **pre-export format check** in [accuracy-checklist.md](references/accuracy-checklist.md#pre-export-format-check): no inline `label:` shortcuts in any element.
2. Call `export_to_excalidraw` with the final JSON to publish to `excalidraw.com`
3. Share the returned URL
4. Offer to save the cited model alongside it as a `.md` file in the repo so future readers can verify the diagram

## MCP Tools Reference

| Tool | Purpose |
|------|---------|
| `read_me` | Fetch the Excalidraw element format reference (call once per conversation) |
| `create_view` | Render an animated Excalidraw diagram inline |
| `save_checkpoint` | Persist user-edited state from the inline view |
| `read_checkpoint` | Restore a previous diagram state to iterate on |
| `export_to_excalidraw` | Upload the diagram to excalidraw.com and return a shareable URL |

## Rules

- **Always cite.** Every shape and arrow must trace to a file:line in the repo. No citation, no element.
- **Never invent.** If a component is not in the code, it is not in the diagram. No "for completeness" boxes.
- **Diagram what is, not what should be.** This is a documentation tool, not a design tool.
- **One diagram type at a time.** If the user wants both auth flow and deployment topology, draw them as two separate diagrams.
- **Spacing constants are non-negotiable.** Never break a constant from `excalidraw-style-guide.md` to fit. Use a bigger camera instead.
- **Always lay out on a grid before writing elements.** Step 5b is not optional unless the diagram has fewer than 4 shapes.
- **Always use standalone text elements.** Never use the inline `label:` shortcut on shapes — it does not survive `export_to_excalidraw`.
- **Always read the format reference once.** Call `read_me` at the start of any conversation that will produce a diagram, then never again.
- **Always start with `cameraUpdate`.** Every `create_view` call must lead with a camera positioning element.
- **Pan the camera as you draw.** Use multiple `cameraUpdate` entries to guide attention; do not draw a complex diagram in a single static view.
- **Approve before drawing** (unless Quick Mode). Never call `create_view` before the user has signed off on the cited model — except in Quick Mode for exploratory diagrams.
- **For "more spacing please" iterations: bump the constants and regenerate.** Never patch coordinates one at a time. See the iteration recipe in `excalidraw-style-guide.md`.
- **Use the Explore subagent for big repos.** Anything over ~50 files of relevant code should be explored via a subagent to protect context.
- **Hand the cited model back with the diagram.** Offer to save it as a markdown file alongside the diagram URL — the citations are the proof of accuracy.
