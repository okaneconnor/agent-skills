# Excalidraw Style Guide

This file is the **opinionated companion** to the Excalidraw MCP `read_me` reference. The MCP reference covers the element format, full colour palette, camera rules, and worked examples — call it once per conversation and treat it as canonical for syntax. This file covers the higher-level choices for **architecture diagrams specifically**: which colours to pick, when to use which shapes, how to make a diagram readable at the inline 700px width.

## Colour assignments (architecture-specific)

The MCP `read_me` exposes the full palette. For codebase diagrams, use this fixed assignment so colours mean the same thing across every diagram you produce. Consistency is what makes the second diagram you draw understandable to someone who saw the first one.

| Component family | Fill | Stroke | Notes |
|------------------|------|--------|-------|
| Web / frontend | `#a5d8ff` | `#4a9eed` | Browser, SPA, static site, CDN edge |
| API / service / backend | `#d0bfff` | `#8b5cf6` | HTTP services, gRPC services, internal APIs |
| Worker / background job | `#ffd8a8` | `#f59e0b` | Queue consumers, cron jobs, schedulers |
| Database / persistent store | `#c3fae8` | `#06b6d4` | Postgres, MySQL, Mongo, blob storage, S3 |
| Cache | `#fff3bf` | `#f59e0b` | Redis, Memcached, in-memory caches |
| Queue / topic / event bus | `#ffd8a8` | `#f59e0b` | Use a **diamond** shape, not a rectangle |
| Identity provider | `#fff3bf` | `#f59e0b` | Auth0, Entra, Cognito, Keycloak |
| External SaaS / third party | `#eebefa` | `#ec4899` | Anything outside the team's control |
| Secret / credential store | `#ffc9c9` | `#ef4444` | Key Vault, Secrets Manager, sealed secrets |
| User / actor | `#a5d8ff` | `#4a9eed` | The human at the keyboard |

For **trust zones** (security and topology diagrams) use the background zone palette at `opacity: 30`:

| Zone | Hex |
|------|-----|
| Public internet | `#fff3bf` |
| DMZ / edge | `#dbe4ff` |
| Application subnet | `#e5dbff` |
| Data subnet | `#d3f9d8` |
| Management plane | `#eebefa` |

## Shape vocabulary

Pick the shape based on what the component **is**, not what looks pretty:

| Shape | Means |
|-------|-------|
| Rectangle (rounded) | A service, a process, a piece of code that runs |
| Diamond | A queue, topic, or event bus (something async) |
| Ellipse | An actor (user, role, identity), or a data store when you want it visually distinct |
| Cylinder approximation (tall ellipse) | Database — only if the diagram has both queues and DBs and you need to disambiguate |

Always prefer **labelled shapes** (the `label` field on the shape) over standalone text elements. The MCP auto-centres labels and resizes the container. Standalone text only for titles, zone labels, and footnotes.

## Arrow vocabulary

| Style | Means |
|-------|-------|
| Solid black | Synchronous call (HTTP, gRPC, function call) |
| Solid coloured (matches source) | Synchronous call, when there are many overlapping arrows and you need to distinguish them |
| Dashed | Async / fire-and-forget (queue publish, event emit, callback) |
| Dotted (`strokeStyle: dotted`) | Conditional / fallback / failure path |
| Red `#ef4444` | Layering violation, deprecated path, or known broken edge |
| Double-headed | Bidirectional (use sparingly — usually two arrows is clearer) |

Every arrow gets a **label** unless its meaning is genuinely obvious from context. Good labels: `JWT`, `gRPC`, `publish: orders.v1`, `read replica`, `mTLS`. Bad labels: `data`, `info`, `request`.

## Layout rules

These come from the MCP reference but bear repeating because breaking them ruins the diagram:

- **Minimum shape size: 120×60** for any labelled rectangle
- **Minimum gap between shapes: 20–30px** — otherwise the labels collide
- **Minimum font size: 16** for body text, **20** for titles
- **Camera sizes are 4:3 only**: 400×300, 600×450, 800×600, 1200×900, 1600×1200
- **Always start `create_view` with a `cameraUpdate`** — never let the viewport be implicit
- **Stream order = z-order** — emit background zones first, then shapes, then labels, then arrows
- **Pan the camera as you draw** — multiple `cameraUpdate` calls in one elements array make a complex diagram readable

## Choosing a camera plan

| Diagram size | First camera | Final camera |
|--------------|--------------|--------------|
| Small (≤6 components, single concept) | Camera M (600×450) | Camera M |
| Medium (≤12 components) | Camera M for the title | Camera L (800×600) |
| Large (≤25 components) | Camera M for the title | Camera XL (1200×900) — fontSize ≥18 |
| Very large (>25 components) | Camera L for orientation | Camera XXL (1600×1200) — fontSize ≥21 |

For any diagram with more than ~8 components, plan **at least 3 camera moves**: title, walking through subsections, final overview. Static diagrams with one camera position are boring and waste the MCP's biggest readability lever.

## Text contrast (on white)

The MCP `read_me` warns about this and it bites people:

- **Body text on white:** never lighter than `#757575`. Default to `#1e1e1e`.
- **Coloured text on light fills:** use the **dark variant** of the colour, not the bright one.
  - On `#a5d8ff` (light blue) → use `#2563eb`, not `#4a9eed`
  - On `#b2f2bb` (light green) → use `#15803d`, not `#22c55e`
  - On `#d0bfff` (light purple) → use `#6d28d9`, not `#8b5cf6`
  - On `#ffd8a8` (light orange) → use `#c2410c`, not `#f59e0b`
- **Stroke colours on shapes:** use the matching primary colour (the column 2 entries above)
- **Never use emoji in text** — Excalidraw's font does not render them

## Streaming order recipe

For any diagram, emit elements in this order to make the draw-on animation make sense:

1. `cameraUpdate` (initial title view)
2. Title text
3. `cameraUpdate` (zoom out to the full diagram)
4. Background zones / trust boundaries (lowest z-order)
5. For each component cluster (left-to-right or top-to-bottom):
   - The shape
   - Its label (if not using the inline `label` field)
   - The arrows leaving it
   - Any annotations
6. Cross-cluster arrows last
7. `cameraUpdate` to a final overview

The bad pattern (do not do this): all rectangles, then all text, then all arrows. It draws like a printer, not like a thought.

## Iteration with checkpoints

Every `create_view` returns a `checkpointId`. Use it.

- After the first render, ask the user **"want to change anything?"** — they will almost always have one or two tweaks
- For tweaks, do **not** re-send the whole element array. Use:
  ```
  [{"type":"restoreCheckpoint","id":"<checkpointId>"}, ...new or replacement elements...]
  ```
- To replace an element: emit `{"type":"delete","ids":"<id>"}` then re-add with a **new id**
- Never reuse a deleted id

This pattern keeps token usage flat across iterations.

## Dark mode

If the user asks for a dark theme:

1. First element of the elements array (before `cameraUpdate`):
   ```
   {"type":"rectangle","id":"darkbg","x":-4000,"y":-3000,"width":10000,"height":7500,
    "backgroundColor":"#1e1e2e","fillStyle":"solid","strokeColor":"transparent","strokeWidth":0}
   ```
2. Swap the architecture colour assignments to the dark variants from the MCP `read_me` reference (Dark Blue `#1e3a5f`, Dark Purple `#2d1b69`, etc.)
3. Text becomes `#e5e5e5` for primary, `#a0a0a0` for secondary
4. Stroke colours stay bright — the primary palette already pops on dark

## Don'ts

- Do not call `read_me` more than once per conversation — it returns the same content every time
- Do not invent shapes the MCP does not support (no clouds, no servers, no actor stick figures unless built from primitives)
- Do not use emoji in any label
- Do not nest more than 2 levels of zones — readability collapses
- Do not draw two diagram types in one `create_view` call — split them
- Do not use Camera S as the final camera for anything bigger than 3 elements
- Do not skip the cited model approval step in SKILL.md just because the diagram seems "obvious" — accuracy is the whole point of this skill
