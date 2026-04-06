# Accuracy Checklist

The whole point of this skill is to produce diagrams a reader can **trust without re-reading the codebase**. That trust is earned by running every cited model through this checklist before calling `create_view`. If anything fails, fix the model and run the checklist again.

Run this in two passes: a **completeness** pass (what is missing) and a **correctness** pass (what is wrong).

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
4. The user has explicitly said "render" or equivalent to the cited model

If any of those four are missing, **do not draw**. Either fix the model or go back to the user.
