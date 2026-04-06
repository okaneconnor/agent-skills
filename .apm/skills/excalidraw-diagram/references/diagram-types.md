# Diagram Type Catalogue

Layout blueprints for the seven diagram types this skill produces. Each entry tells you what to draw, where to put it on the canvas, which colour palette to lean on, and which camera moves to plan up front.

All sizes assume the default `cameraUpdate` of `800×600` (Camera L) unless otherwise stated. The canvas is white. Element format is documented in the Excalidraw MCP `read_me` reference — call it once per conversation before drawing.

## 1. Architecture overview

**Goal:** the "single screenshot you put in the README".

**Layout:** layered top-to-bottom. Public internet at the top, application tier in the middle, data tier at the bottom. Side panels for external dependencies and operational concerns.

```
+--------------------------------------------------+
|                  Public Internet                 |
+----+--------------------------------+------------+
     |                                |
     v                                v
+-----------+   +-----------+   +-----------+
|   Web     |   |    API    |   |  Worker   |
+-----+-----+   +-----+-----+   +-----+-----+
      |               |               |
      +---------+-----+----+----------+
                |          |
                v          v
          +-----------+ +---------+
          | Postgres  | |  Redis  |
          +-----------+ +---------+
```

**Colours:**
- Frontend / web: `#a5d8ff` (light blue) on `#4a9eed` border
- API / services: `#d0bfff` (light purple) on `#8b5cf6` border
- Workers / background: `#ffd8a8` (light orange) on `#f59e0b` border
- Data stores: `#c3fae8` (light teal) on `#06b6d4` border
- External SaaS: `#eebefa` (light pink) on `#ec4899` border

**Camera plan:**
1. Camera M (600×450) on the title
2. Camera L (800×600) on the full graph
3. Optional Camera XL (1200×900) at the end if there are >12 nodes

## 2. Auth flow

**Goal:** show the token lifecycle. This is a sequence diagram.

**Layout:** four to six actors as columns, lifelines as dashed vertical arrows, messages as labelled horizontal arrows top-to-bottom.

Standard actors (left to right):

```
| User |  | Browser |  | App Backend |  | Identity Provider |  | Resource API |
```

Use the **sequence flow** example from the Excalidraw `read_me` reference as a starting template. Number the messages: `1. /login`, `2. 302 -> IdP`, `3. authn`, `4. code`, `5. token exchange`, `6. id_token + access_token`, `7. set session cookie`, `8. /api/me + Bearer`, `9. 200 OK`.

**Colours:**
- User actor header: `#a5d8ff`
- Browser actor header: `#b2f2bb`
- Backend actor header: `#d0bfff`
- IdP actor header: `#ffd8a8`
- Resource API header: `#fff3bf`
- Successful messages: solid arrow, `#1e1e1e`
- Token / credential messages: solid arrow, `#8b5cf6`
- Async returns: dashed arrow, `#f59e0b`

**Camera plan:**
1. Camera M on the title
2. Camera S (400×300) zooming into each actor column right-to-left as you draw the headers and lifelines
3. Camera M panning down the message sequence
4. Camera L final overview

## 3. Security model

**Goal:** show **trust boundaries** and which arrows cross them.

**Layout:** nested zone rectangles. Public internet wraps a DMZ wraps application zones wraps data zones. Use the **background zones** with `opacity: 30`:

- Public internet zone: `#fff3bf` opacity 30, label "Public Internet"
- DMZ zone: `#dbe4ff` opacity 30, label "DMZ"
- App zone: `#e5dbff` opacity 30, label "Application Subnet"
- Data zone: `#d3f9d8` opacity 30, label "Data Subnet"
- Management zone: `#eebefa` opacity 30, label "Management Plane"

```
+============== Public Internet ===============+
| +---------- DMZ ----------+                   |
| |  WAF     LB    Bastion  |                   |
| +------+-----------+------+                   |
|        |           |                          |
|        v           v                          |
| +======== Application Subnet ========+        |
| |  API   Worker   Auth Middleware    |        |
| +-----+----------+--------------+----+        |
|       |          |              |             |
|       v          v              v             |
| +========= Data Subnet ===========+           |
| |  PG (TLS)  Redis  Blob Storage  |           |
| +---------------------------------+           |
+================================================+
```

Every arrow that crosses a zone gets a label describing the **trust transition**: "JWT validated", "mTLS", "managed identity", "private endpoint only".

**Camera plan:**
1. Camera L on the full layout
2. Camera S zooming into each ingress point in turn to highlight the validation step
3. Camera XL (1200×900) at the end for the panorama

## 4. Data flow

**Goal:** trace one record from its source to its sink.

**Layout:** left-to-right linear flow with branches. Each shape is a processing stage; each arrow is the record moving (with the schema name on the label).

```
[Webhook] -> [Validate] -> [Enrich] -> [Topic: orders.v1] -> [Worker] -> [Postgres: orders]
                                                  |
                                                  +--> [Audit log: blob://orders/audit/]
```

**Colours:**
- Producer / source: `#a5d8ff`
- Transform / validate: `#fff3bf`
- Async hop (queue/topic): `#ffd8a8` with diamond shape
- Sink / store: `#c3fae8`
- Side effect: `#eebefa`

Label every arrow with the **schema or payload name**, not just "data". Bonus: include the schema version (`orders.v1`).

**Camera plan:**
1. Camera M on the title
2. Camera L on the full pipeline
3. Camera S zooming into each hop in order as the arrows draw, so the user can read the labels

## 5. Deployment topology

**Goal:** show **where the code physically runs**.

**Layout:** nested rectangles representing the infrastructure hierarchy:

```
Cloud Provider
 └── Subscription / Account
     └── Region (e.g. uksouth)
         └── VNet / VPC
             └── Subnet
                 └── Cluster / Compute Host
                     └── Container / Process
```

Draw the outer layers with subtle background fills (zones at opacity 30) and the leaf compute units as filled rectangles in the colour palette from the architecture overview.

If the system spans multiple regions, draw each region as a side-by-side block and show replication arrows between them with a labelled dashed line ("async replication", "synchronous", "DR only").

**Camera plan:**
1. Camera L on the cloud-level wrapper
2. Camera M zooming into each region in turn
3. Camera XL for the final panorama (especially for multi-region)

## 6. Sequence flow

**Goal:** time-ordered "what happens when X" walkthrough.

This is the same shape as the auth flow diagram but for arbitrary actors. Reuse the sequence pattern from the Excalidraw `read_me` reference verbatim — it is the canonical example.

When to use over a flow chart: when the answer to "what does this do" depends on **the order** of operations. Webhook handling, retries, async callbacks, distributed transactions.

## 7. Module dependency

**Goal:** show how internal packages depend on each other.

**Layout:** force-directed graph is unreadable in Excalidraw. Use a **layered DAG** instead:

- Layer 0 (top): public APIs / entry points
- Layer 1: feature modules
- Layer 2: shared libraries
- Layer 3 (bottom): platform / utility packages

Arrows point from the dependent to the dependency (i.e. downward). Every arrow that points **upward** is a layering violation and should be drawn in red.

**Colours:**
- Public surface: `#a5d8ff`
- Feature modules: `#d0bfff`
- Shared libraries: `#fff3bf`
- Utility packages: `#c3fae8`
- Layering violations: `#ef4444` arrow + `#ffc9c9` highlight

## Universal layout rules

These apply to every diagram type. Treat them as defaults and only break them with a reason.

| Rule | Why |
|------|-----|
| Minimum shape size 120×60 | Anything smaller is unreadable at 700px display |
| Minimum 20–30px gap between shapes | Otherwise labels overlap |
| Minimum body fontSize 16, title 20 | Smaller text becomes pixel mush |
| Always start with `cameraUpdate` | The MCP rejects implicit viewports |
| 4:3 camera ratios only | Non-4:3 distorts the diagram |
| Stream order = back-to-front z-order | Background zones first, arrows last |
| One labelled arrow per relationship | Two parallel arrows are fine; three is clutter |
| Trust boundaries always at opacity 30 | Solid zones drown out the foreground |

## Picking the right type

If the user has not specified a type:

- "What does this do at a high level?" → architecture overview
- "How does login / auth / SSO work?" → auth flow (sequence variant)
- "Is this secure?" / "Show me the trust boundaries" → security model
- "How does data move?" / "Where do orders end up?" → data flow
- "Where does this run?" / "Show me prod" → deployment topology
- "Walk me through what happens when X" → sequence flow
- "Are these packages tangled?" → module dependency

If two types fit, pick one and offer to draw the other separately. Never combine two types into a single diagram — readability collapses.
