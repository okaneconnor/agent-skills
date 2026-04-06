# Excalidraw Style Guide

This file is the **opinionated companion** to the Excalidraw MCP `read_me` reference. The MCP reference covers element format, full colour palette, camera rules, and worked examples — call it once per conversation and treat it as canonical for syntax. This file covers the higher-level choices for **architecture diagrams specifically**: spacing, colours, shapes, text, iteration.

> **Read this section first, every time.** Spacing is the single biggest reason architecture diagrams look bad. If you remember nothing else, remember the constants below.

## Spacing constants — HARD RULES

These are not suggestions. Treat them as a contract. Every layout in this skill is designed against these numbers; every blueprint and accuracy check refers back to them by name. Diagrams that break a constant are rejected at the spacing audit pass.

| Constant | Value | Applies to |
|---|---|---|
| `GAP_SHAPE_H` | **80px** | Minimum horizontal gap between two shapes on the same row |
| `GAP_SHAPE_V` | **100px** | Minimum vertical gap between two shapes on different rows |
| `GAP_LAYER` | **140px** | Minimum vertical gap between two layers in a layered architecture (e.g. web → API → data) |
| `GAP_ACTOR_COL` | **220px** | Minimum horizontal gap between actor lifelines in a sequence diagram |
| `GAP_ZONE_INNER` | **40px** | Minimum padding from a zone background border to any shape inside it |
| `GAP_ZONE_OUTER` | **60px** | Minimum gap between two adjacent zone backgrounds |
| `GAP_LABEL_CLEAR` | **20px** | Minimum clear space around any standalone text label (no shape, arrow, or other label inside this radius) |
| `MARGIN_CANVAS` | **60px** | Minimum margin from any visible camera edge to the nearest element |
| `ARROW_LEN_LABELLED` | **140px** | Minimum length for any arrow that carries a label |
| `ARROW_LEN_UNLABELLED` | **80px** | Minimum length for any arrow without a label |
| `ARROW_PARALLEL_GAP` | **40px** | Minimum perpendicular distance between two parallel arrows (otherwise they merge visually) |
| `SHAPE_MIN_W` | **160px** | Minimum width for any labelled rectangle (was 120; bumped because labels were getting clipped) |
| `SHAPE_MIN_H` | **70px** | Minimum height for any labelled rectangle |
| `FAN_OUT_ANGLE` | **30°** | Minimum angular separation between sibling arrows fanning out from a shared origin |

**Why these numbers, in plain language:**

- **80px / 100px shape gaps** — at the inline 700px display width, anything tighter than this looks like the shapes are touching even when they technically aren't. The eye reads them as a single blob.
- **140px layer gap** — gives enough room for an arrow with a label between layers without the label crowding either shape.
- **220px actor columns** — sequence diagrams need enough horizontal room for arrow labels (`tools/call`, `Bearer + JWT`, `302 redirect`) to sit on the arrow without colliding with the lifelines.
- **40px / 60px zone padding** — without it, shapes inside a trust zone visually fuse with the zone border and the boundary disappears.
- **140px labelled arrow** — labels need horizontal real estate. Anything shorter cramps the label against an endpoint.
- **40px parallel arrow gap** — two arrows running side by side at <40px read as a single arrow with a doubled stroke.

**The first rule of every diagram is that it must pass the spacing audit in `accuracy-checklist.md`.** If a layout cannot fit at these numbers in your chosen camera, the answer is a bigger camera, not smaller spacing.

## Grid-first layout planning

**Do not write element coordinates straight from your head.** That is how you end up with 80 elements at "almost-but-not-quite" positions and a tweak request that forces a full rewrite.

Instead, lay the diagram out on a coordinate grid **before** emitting any elements:

1. Pick the camera size (Camera M / L / XL / XXL — see the camera plan table below).
2. Subtract `MARGIN_CANVAS` from each edge to get your **drawable area**.
3. Decide your **row** and **column** boundaries on that grid using the spacing constants. For a 3-row architecture overview in Camera L (800×600), the rows are at:
   - row 1 baseline `y = 60` (top margin)
   - row 2 baseline `y = 60 + SHAPE_MIN_H + GAP_LAYER = 60 + 70 + 140 = 270`
   - row 3 baseline `y = 270 + 70 + 140 = 480`
   - Final shape bottoms at `480 + 70 = 550`. Camera height 600 → 50px bottom margin. ✓
4. Compute every shape's `(x, y, width, height)` from those row/column anchors. Write the anchors down before writing any element JSON.
5. Now emit elements.

This sounds like overhead but it makes spacing-related rework a one-line change. "Add 30px more vertical padding" becomes "increase `GAP_LAYER` from 140 to 170, recompute row 2 and row 3" — not "manually shift 80 elements".

When the user asks for "more spacing", **never** patch individual element coordinates. Bump the constants and regenerate from the cited model. See the iteration recipe below.

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

Every labelled rectangle MUST be at least `SHAPE_MIN_W × SHAPE_MIN_H` (160×70). Smaller shapes truncate the label or get drowned out by the surrounding gaps.

## Inline vs export — the format divergence rule

This is the single biggest gotcha in the Excalidraw MCP and it has burned us. Read it twice.

**`create_view` and `export_to_excalidraw` accept different element formats.**

- `create_view` supports a `label: { text: "...", fontSize: ... }` shortcut on shapes — the MCP auto-centres the label inside the shape and resizes the container to fit.
- `export_to_excalidraw` does **not** honour this shortcut. Inline labels render as **empty boxes** in the exported file. The text is silently dropped.

**Therefore: never use the inline `label:` shortcut.** Always emit text as a separate `text` element with explicit `x`, `y`, `text`, `fontSize`, and (where needed) `fontFamily`. Yes, this costs more tokens. The cost of an empty exported diagram is much higher.

Recipe for a labelled shape:

```json
[
  {"type":"rectangle","id":"r1","x":120,"y":120,"width":200,"height":80,
   "roundness":{"type":3},"backgroundColor":"#a5d8ff","fillStyle":"solid","strokeColor":"#4a9eed"},
  {"type":"text","id":"r1_label","x":160,"y":146,"text":"Web App","fontSize":20,"strokeColor":"#1e1e1e"}
]
```

Note: the text `x` is the **left edge**, not the centre. To centre a label inside a 200×80 shape positioned at `(120, 120)`:

- target centre `cx = 120 + 200/2 = 220`
- estimated text width `w ≈ len(text) * fontSize * 0.5 = 7 * 20 * 0.5 = 70`
- text `x = cx - w/2 = 220 - 35 = 185`
- text `y = shape_y + (shape_height - fontSize) / 2 ≈ 120 + (80 - 20)/2 = 150`

This is annoying. It is also non-negotiable if you want export to work. See the centering recipe below for the formula in one line.

## Text positioning recipes

The MCP positions text by its **left edge** at `(x, y)`. There is no `centerAt` field, no `textAlign: "center"` that affects positioning, no auto-centring. If you want centred text, you compute it.

### Centering formula

```
text_x = center_x - (len(text) * fontSize * 0.5) / 2
text_y = center_y - fontSize / 2
```

Where `0.5` is the empirical character-width ratio for Excalidraw's default font. This is approximate — long titles still need a manual eyeball pass.

### Centering inside a shape

```
text_x = shape_x + (shape_width  - len(text) * fontSize * 0.5) / 2
text_y = shape_y + (shape_height - fontSize) / 2
```

### Centering a title above a diagram

```
text_x = diagram_center_x - (len(title) * title_fontSize * 0.5) / 2
text_y = diagram_top_y - title_fontSize - 20
```

(20px clear space above the diagram, then the title sits above that.)

### Long titles

For titles over ~25 characters, the `0.5` ratio undercounts. Bump to `0.55` and add a manual 10px slack on the right. If the title still looks off-centre in the rendered preview, treat it as a single iteration and tweak.

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

**Arrow length minimums:**

- Labelled arrows: minimum `ARROW_LEN_LABELLED` (140px). Shorter and the label cramps the endpoint.
- Unlabelled arrows: minimum `ARROW_LEN_UNLABELLED` (80px).
- Two parallel arrows: must be at least `ARROW_PARALLEL_GAP` (40px) apart, or merge them visually.

When fanning multiple arrows out from one shape, the **angular** separation between siblings must be at least `FAN_OUT_ANGLE` (30°) — otherwise the arrowheads collide at the destinations.

## Layout rules (consolidated)

These come from the spacing constants but bear repeating. Breaking any one of them ruins the diagram:

- Minimum shape size: `SHAPE_MIN_W × SHAPE_MIN_H` (160×70) for labelled rectangles
- Minimum gap between shapes: `GAP_SHAPE_H` (80px) horizontal, `GAP_SHAPE_V` (100px) vertical
- Minimum gap between layers: `GAP_LAYER` (140px)
- Minimum zone padding: `GAP_ZONE_INNER` (40px), `GAP_ZONE_OUTER` (60px)
- Minimum canvas margin: `MARGIN_CANVAS` (60px)
- Minimum labelled arrow length: `ARROW_LEN_LABELLED` (140px)
- Minimum body fontSize: 16 (inline render); see export caveat below
- Minimum title fontSize: 20 (inline render)
- Camera sizes are 4:3 only: 400×300, 600×450, 800×600, 1200×900, 1600×1200
- Always start `create_view` with a `cameraUpdate`
- Stream order = z-order — emit background zones first, then shapes, then labels, then arrows
- Pan the camera as you draw — multiple `cameraUpdate` calls per `create_view`

## Font sizes — inline vs exported

The font minimums in this guide assume the **inline** rendering at ~700px. Exported `.excalidraw` files are usually viewed at full resolution where smaller fonts are still readable. Concretely:

| Use case | Body min | Title min | Annotation min |
|---|---|---|---|
| Inline render (Camera L / XL) | 16 | 20 | 14 |
| Inline render (Camera XXL) | 18 | 24 | 16 |
| Exported file viewed full-screen | 12 | 16 | 10 |

If you know the diagram is heading straight to `export_to_excalidraw` (e.g. the user said "export it") and will be shared as a file rather than shown inline, you may use the export column. Otherwise stick to the inline minimums.

## Choosing a camera plan

| Diagram size | First camera | Final camera | Notes |
|--------------|--------------|--------------|-------|
| Small (≤6 components) | Camera M (600×450) | Camera M | Single concept |
| Medium (≤12 components) | Camera M for the title | Camera L (800×600) | Default workhorse |
| Large (≤25 components) | Camera M for the title | Camera XL (1200×900) | fontSize ≥18 |
| Very large (>25 components) | Camera L for orientation | Camera XXL (1600×1200) | fontSize ≥21 |
| Wide landscape (single row, many columns) | Camera M for the title | Two paired Camera L panning horizontally — see Landscape recipe below | The 4:3 constraint hurts here; pan instead |

For any diagram with more than ~8 components, plan **at least 3 camera moves**: title, walking through subsections, final overview. Static diagrams with one camera position are boring and waste the MCP's biggest readability lever.

## Landscape recipe (workaround for the 4:3 constraint)

The Excalidraw MCP only accepts 4:3 cameras. Architecture diagrams are usually wide. Here is the workaround:

**Pattern: paired panning cameras.**

1. Lay out the diagram across a wide drawable area (e.g. 1500px wide × 600px tall).
2. Use **two Camera L (800×600)** views in sequence: the first centred on the left half, the second on the right half, with ~100px overlap.
3. Emit the left-half elements after the first `cameraUpdate`, then emit the right-half elements after the second.
4. End with a Camera XL (1200×900) framing the whole thing for the final overview.

```json
[
  { "type": "cameraUpdate", "width": 800, "height": 600, "x": 0,   "y": 0 },
  // ... left-half elements (x in [60, 800]) ...
  { "type": "cameraUpdate", "width": 800, "height": 600, "x": 700, "y": 0 },
  // ... right-half elements (x in [800, 1500]) ...
  { "type": "cameraUpdate", "width": 1200, "height": 900, "x": 100, "y": -150 }
]
```

This is genuinely better than cramming a wide diagram into a single 4:3 camera — the user gets a guided pan across the topology, then a final wide shot. For very wide canvases (>2000px), use three cameras instead of two.

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
   - Its standalone text label
   - The arrows leaving it (with their standalone arrow labels)
   - Any annotations
6. Cross-cluster arrows last
7. `cameraUpdate` to a final overview

The bad pattern (do not do this): all rectangles, then all text, then all arrows. It draws like a printer, not like a thought.

## Iteration recipe

When the user asks for changes, choose the right tool for the change:

| Change type | Right tool |
|---|---|
| "Move that one box left" | `restoreCheckpoint` + `delete` + re-add (single element) |
| "Rename this label" | `restoreCheckpoint` + `delete` text + re-add text |
| "Add an arrow from X to Y" | `restoreCheckpoint` + just emit the new arrow |
| "More spacing please" | **Bump the spacing constants and regenerate the entire elements array from the cited model.** Do not patch coordinates one by one. |
| "Make it landscape" | Recompute against the landscape recipe above; full regenerate |
| "Different colour scheme" | `restoreCheckpoint` + `delete` all shapes + re-add with new colours |

**The cited model (from SKILL.md Step 3) is the source of truth.** Coordinates are derived from it. Any change that affects layout-wide properties — spacing, camera, orientation, colour scheme — should be a regenerate, not a patch. The cited model never changes; the rendering does.

**Tactical:** for a regenerate, you do NOT need to re-prove every citation. The model is already approved. You're just laying it out differently.

## Iteration with checkpoints

Every `create_view` returns a `checkpointId`. Use it for the patch-style changes from the table above.

- For tweaks, use:
  ```
  [{"type":"restoreCheckpoint","id":"<checkpointId>"}, ...new or replacement elements...]
  ```
- To replace an element: emit `{"type":"delete","ids":"<id>"}` then re-add with a **new id**
- Never reuse a deleted id

This pattern keeps token usage flat across small iterations. For a full regenerate (spacing changes, layout changes), don't use restoreCheckpoint — start fresh.

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
- Do not use the inline `label:` shortcut on shapes — it does not survive `export_to_excalidraw`. Always use standalone text elements.
- Do not write coordinates straight from your head — lay out on a grid first, with the spacing constants
- Do not break a spacing constant to "make it fit" — use a bigger camera instead
- Do not patch coordinates one by one for a "more spacing" request — bump the constants and regenerate
- Do not invent shapes the MCP does not support (no clouds, no servers, no actor stick figures unless built from primitives)
- Do not use emoji in any label
- Do not nest more than 2 levels of zones — readability collapses
- Do not draw two diagram types in one `create_view` call — split them
- Do not use Camera S as the final camera for anything bigger than 3 elements
- Do not skip the cited model approval step in SKILL.md unless the user explicitly asks for quick mode (see SKILL.md)
