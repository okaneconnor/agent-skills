# Accuracy Checklist

The whole point of this skill is to produce diagrams a reader can **trust without re-reading the codebase**. That trust is earned by running every cited model through this checklist before calling `create_view`. If anything fails, fix the model and run the checklist again.

Run this in **four passes**: completeness (what is missing), correctness (what is wrong), drawability (does it fit), and **spacing** (is it well-spaced enough to actually read).

## Pass 1 — Completeness

For the diagram type you picked, are all the required elements present?

### Architecture overview
- [ ] Every entry point found in Phase 1 of the analysis is on the diagram, OR explicitly excluded with a reason
- [ ] Every persistent data store (DB, blob, search index) appears as a node
- [ ] Every external SaaS dependency the code calls appears as a node
- [ ] Every internal-to-internal RPC / queue / API edge has an arrow
- [ ] The runtime host (cluster / serverless / VM) is at least labelled, even if not drawn as a separate shape

### Auth flow
- [ ] The user actor is on the diagram
- [ ] The browser / client actor is on the diagram if there is one
- [ ] The identity provider is named (not just "IdP")
- [ ] The redirect / callback URI is labelled on the relevant arrow
- [ ] The token type (JWT, opaque session, API key) is labelled
- [ ] The validation point (middleware that checks the token on the resource side) is shown
- [ ] If there is a refresh flow, it is shown — or its absence is noted

### Security model
- [ ] Every trust zone identified in Phase 2 has a labelled background rectangle
- [ ] Every arrow that crosses a zone boundary has a label describing the trust transition
- [ ] All ingress points (load balancer, gateway, ingress) are visible
- [ ] Every secret store is on the diagram, with arrows showing what reads from it
- [ ] Every workload identity / managed identity / service account is at least named

### Data flow
- [ ] The producer (source of the record) is on the leftmost edge
- [ ] The final sink is on the rightmost edge
- [ ] Every intermediate hop (queue, transform, validation, enrichment) is a labelled node
- [ ] Every arrow carries the **schema name and version** of the record at that point
- [ ] Side effects (audit logs, metrics, dead-letter queues) are branches off the main flow

### Deployment topology
- [ ] The cloud provider is labelled
- [ ] The region(s) are labelled
- [ ] The network boundary (VNet / VPC) is drawn
- [ ] Each compute host's runtime type (container, function, VM) is visible from the shape or label
- [ ] Cross-region replication arrows have a label (sync / async / DR)

### Sequence flow
- [ ] All actors that participate in the flow have a header and a lifeline
- [ ] Messages are numbered or visually ordered top-to-bottom
- [ ] Every message has a label
- [ ] Async returns use a dashed arrow
- [ ] Conditional / failure branches are shown if they materially change the outcome

### Module dependency
- [ ] Every internal package is a node
- [ ] Every cross-package import is an arrow
- [ ] Layers are visually obvious (top-to-bottom or left-to-right)
- [ ] Layering violations are highlighted in red

## Pass 2 — Correctness

For each component and edge in the model, prove the citation.

- [ ] **Every component has a `file:line` citation.** No exceptions, even if it "obviously" exists.
- [ ] **Every edge has a `file:line` citation.** The citation is the file where you can see the call / publish / dependency happen.
- [ ] **No invented names.** Component names match either the code identifier or the IaC resource name. If you renamed it for clarity, mention the original in the citation line.
- [ ] **No invented edges.** Every arrow corresponds to a real call site or a real IaC dependency, not "this is probably how it works".
- [ ] **No duplicated nodes.** If the same service appears under two names in the code, pick one and merge the citations.
- [ ] **Docs vs code conflicts resolved in favour of code.** If `README.md` says the API talks to MySQL but `terraform/main.tf` provisions Postgres, draw Postgres and add a note.
- [ ] **No future-tense components.** "We're going to add a queue here" is not on the diagram. Diagram what exists.
- [ ] **Open questions are listed**, not silently ignored. If you could not verify something, flag it under `## Open questions` in the model and ask the user before drawing.

## Pass 3 — Drawability

The model is correct, but can it actually be drawn well?

- [ ] **Component count is reasonable for the chosen camera.** ≤6 fits Camera S, ≤12 fits Camera L, ≤25 fits Camera XL, anything more needs a Camera XXL panorama or to be split across multiple diagrams.
- [ ] **Edge count is reasonable.** If you have more than 3 arrows leaving a single node, consider whether the diagram is the right shape.
- [ ] **Labels fit.** No arrow label longer than ~20 characters unless the arrow is wider than 200px.
- [ ] **No "everything connects to everything"** spaghetti. If you see this, the diagram type is probably wrong (try sequence or data flow instead).
- [ ] **The diagram answers the user's question.** Re-read the original ask. Does the model in front of you answer it?

## Pass 4 — Spacing audit

**This is the pass that catches the "looks cramped" failure mode.** The skill's spacing constants in [`excalidraw-style-guide.md`](excalidraw-style-guide.md#spacing-constants--hard-rules) are non-negotiable. Every blueprint in `diagram-types.md` is computed against them. This pass verifies your concrete coordinates honour the contract before you call `create_view`.

Run a numeric scan over your planned coordinates (the grid you laid out in SKILL.md Step 5b) and check each item:

- [ ] **Shape sizes:** every labelled rectangle is at least `SHAPE_MIN_W × SHAPE_MIN_H` (160 × 70). No exceptions for "small annotations" — if it has a label, it gets the minimum.
- [ ] **Horizontal shape gaps:** every pair of shapes on the same row has at least `GAP_SHAPE_H` (80px) between them. Measure from right edge of left shape to left edge of right shape.
- [ ] **Vertical shape gaps:** every pair of shapes on different rows has at least `GAP_SHAPE_V` (100px) between them.
- [ ] **Layered diagrams:** every pair of consecutive layers is separated by at least `GAP_LAYER` (140px).
- [ ] **Sequence diagrams:** every pair of adjacent actor lifelines is at least `GAP_ACTOR_COL` (220px) apart.
- [ ] **Trust zones:** every shape inside a zone is at least `GAP_ZONE_INNER` (40px) from the zone border. Adjacent zones are at least `GAP_ZONE_OUTER` (60px) apart.
- [ ] **Canvas margin:** no element is within `MARGIN_CANVAS` (60px) of the visible camera edge for that section.
- [ ] **Labelled arrow length:** every arrow that carries a label is at least `ARROW_LEN_LABELLED` (140px) long. Measure: `sqrt(dx^2 + dy^2)`.
- [ ] **Unlabelled arrow length:** every other arrow is at least `ARROW_LEN_UNLABELLED` (80px).
- [ ] **Parallel arrows:** any two parallel arrows are at least `ARROW_PARALLEL_GAP` (40px) apart perpendicularly. (Two arrows merging visually = one arrow as far as the reader is concerned.)
- [ ] **Fan-out angle:** when multiple arrows leave a single shape going in similar directions, sibling arrows have at least `FAN_OUT_ANGLE` (30°) of angular separation at the origin.
- [ ] **Standalone label clearance:** every standalone text element has at least `GAP_LABEL_CLEAR` (20px) of clear space to any other element. Labels never sit inside another shape's bounds (unless they are intentionally that shape's title).
- [ ] **No accidental overlaps:** scan for any two shapes whose bounding boxes intersect. There should be zero. (This catches the "I forgot to recompute this row after I shifted the column" bug.)
- [ ] **No arrows passing through unrelated shapes:** an arrow's path between source and target must not cross any unrelated shape's bounds. If it does, route differently or move the obstructing shape.

If any item fails, the fix is **not** to nudge individual elements. The fix is to:

1. Identify which spacing constant the violation breaks
2. Bump the relevant constant in your local layout (e.g. `GAP_LAYER += 30`)
3. Recompute the row/column anchors from scratch
4. Regenerate the elements array

This is exactly the iteration recipe from the style guide. **Never patch coordinates one at a time** — that is how spacing problems become permanent.

### Pre-export format check

Before calling `export_to_excalidraw`, run this scan over the elements array. The full reference for each item is in [`export-schema.md`](export-schema.md) — `create_view` is lenient and `export_to_excalidraw` is strict, so a diagram that renders fine inline can still come back as empty boxes after export.

- [ ] **No inline `label:` shortcuts on shapes.** Scan for any shape with a `label:` field. The shortcut is a `create_view` convenience, not part of the wire format — it renders inline and disappears on export. Replace each with a standalone `text` element using the full schema below.
- [ ] **Every text element carries the full Excalidraw text schema.** Each `text` element must have **all** of: `type`, `id`, `x`, `y`, `width`, `height`, `strokeColor`, `text`, `originalText` (matching `text`), `fontSize`, `fontFamily` (default `5`), `textAlign`, `verticalAlign`, `baseline` (≈`fontSize * 0.85`), `containerId` (`null` for standalone), `lineHeight` (`1.25`). Any missing field strips the text on export.
- [ ] **Built via the Python heredoc, not by hand.** A 100-element diagram with hand-written full-schema JSON is impractical — the typo rate is too high. Use the verified builder template in [`export-schema.md`](export-schema.md#builder-template--the-verified-recipe).
- [ ] **JSON file size fits the bash output cap.** Run `wc -c` on the generated file. If it reports more than ~30 KB, the `cat` step that feeds the export call will be truncated. Trim per the size budget in [`export-schema.md`](export-schema.md#size-budget).
- [ ] **2-element smoke test passes for fresh conversations.** If this is the first export of the conversation, run the test from [`export-schema.md`](export-schema.md#the-2-element-smoke-test) before generating the full diagram. Five seconds of verification is much cheaper than three rounds of debugging.

## Failure modes to actively look for

- **The README diagram trap.** You found a diagram in `README.md` and lifted its components. Stop. Read the IaC and confirm the README diagram still matches reality.
- **The "missing worker" trap.** You found the API service but missed the background worker that does the real work. Re-grep for `consumer`, `worker`, `cron`, `scheduled`.
- **The "ghost component" trap.** You added a component the user mentioned in conversation but never appears in the code. Remove it or move it to the open questions.
- **The "stale env" trap.** You read a config file from a dev branch that disagrees with `main`. Always work from the branch the user actually cares about (default: `main`).
- **The "synchronous/asynchronous swap" trap.** You drew a solid arrow for what is actually a queue publish. Check the call site — if it returns immediately and the work happens elsewhere, it is dashed.
- **The "auth happy path only" trap.** Your auth flow shows login but not logout, refresh, or token expiry. At minimum, mention these even if you do not draw them.

## Sign-off

You are ready to call `create_view` when:

1. Pass 1 is fully checked off for your diagram type
2. Pass 2 has zero unresolved items
3. Pass 3 confirms the diagram is drawable at the chosen camera size
4. **Pass 4 confirms every spacing constant is honoured** — no shortcuts
5. The user has explicitly said "render" or equivalent to the cited model (or has opted into Quick Mode in SKILL.md)

If any of these are missing, **do not draw**. Either fix the model, fix the layout, or go back to the user.

You are ready to call `export_to_excalidraw` when:

1. The diagram has been successfully rendered with `create_view`
2. **Every item in the pre-export format check passes** — full text schema, no `label:` shortcuts, size under the cat cap, smoke test green
3. The user has asked to export
4. After exporting, you have **opened the URL and confirmed the text is visible** — the inline render does not prove the export is correct
