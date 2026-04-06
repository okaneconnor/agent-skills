# Diagram Type Catalogue

Layout blueprints for the seven diagram types this skill produces. Each entry tells you what to draw, where to put it on the canvas, which colour palette to lean on, and which camera moves to plan up front.

**All blueprints respect the spacing constants from [`excalidraw-style-guide.md`](excalidraw-style-guide.md#spacing-constants--hard-rules).** If you cannot fit a blueprint at those numbers, the answer is a bigger camera, never tighter spacing.

The canvas is white. Element format is documented in the Excalidraw MCP `read_me` reference — call it once per conversation before drawing.

## Spacing-first layout method

Before you write any element JSON, do this:

1. **Pick the diagram type** from the list below.
2. **Pick the camera** from the size table in `excalidraw-style-guide.md`.
3. **Compute the drawable area** = camera area minus `MARGIN_CANVAS` (60px) on each edge.
4. **Lay out rows and columns** on a grid using the spacing constants. Write down the anchors before any elements.
5. **Then** emit elements.

If you skip steps 1–4 you will end up patching coordinates one at a time, and any spacing change request will trigger a full rewrite. With the grid done first, "more spacing please" is a one-line constant change followed by a regenerate.

---

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

**Spacing budget (Camera L 800×600, 3 shapes per row):**

- Drawable area after `MARGIN_CANVAS`: `(60, 60)` to `(740, 540)`
- Row 1 (web tier): `y = 100`, shape height `SHAPE_MIN_H = 70` → bottom at 170
- Row 2 (api tier): `y = 100 + 70 + GAP_LAYER (140) = 310`, bottom at 380
- Row 3 (data tier): `y = 310 + 70 + GAP_LAYER (140) = 520`, bottom at 590

…which overflows 540. Camera L is too small for a 3-tier overview at the spacing constants. **Use Camera XL (1200×900)** instead, or merge two tiers into one row.

**Spacing budget (Camera XL 1200×900, 3 tiers, 3 shapes per tier):**

- Drawable area: `(60, 60)` to `(1140, 840)` — width 1080, height 780
- Each row holds 3 shapes of `SHAPE_MIN_W (160)` with `GAP_SHAPE_H (80)` gaps → total row width `3*160 + 2*80 = 640`. Centred horizontally → first column at `x = 60 + (1080 - 640)/2 = 280`
- Column anchors: `cx_1 = 280`, `cx_2 = 280 + 160 + 80 = 520`, `cx_3 = 760`
- Row anchors: `y_1 = 100`, `y_2 = 100 + 70 + 140 = 310`, `y_3 = 310 + 70 + 140 = 520`. Bottom of row 3 at 590, with 250px room for arrows / labels below ✓

**Colours:**
- Frontend / web: `#a5d8ff` on `#4a9eed` border, dark text `#2563eb`
- API / services: `#d0bfff` on `#8b5cf6` border, dark text `#6d28d9`
- Workers / background: `#ffd8a8` on `#f59e0b` border, dark text `#c2410c`
- Data stores: `#c3fae8` on `#06b6d4` border
- External SaaS: `#eebefa` on `#ec4899` border

**Camera plan:**
1. Camera M (600×450) on the title
2. Camera XL (1200×900) on the full graph (Camera L only works if you have ≤2 tiers)
3. For very wide single-row layouts, use the **Landscape recipe** in `excalidraw-style-guide.md` (paired panning Camera L)

---

## 2. Auth flow

**Goal:** show the token lifecycle. This is a sequence diagram.

**Layout:** four to six actors as columns, lifelines as dashed vertical arrows, messages as labelled horizontal arrows top-to-bottom.

Standard actors (left to right):

```
| User |  | Browser |  | App Backend |  | Identity Provider |  | Resource API |
```

**Spacing budget (5 actors, Camera XL 1200×900):**

- Actor column anchors with `GAP_ACTOR_COL = 220`: `cx = 120, 340, 560, 780, 1000`
- Each actor header is `SHAPE_MIN_W × SHAPE_MIN_H` (160×70) centred on the column anchor
- Lifeline length: drawable height minus header → ~700px (plenty of vertical room for messages)
- Each message arrow stretches between two adjacent column anchors → length 220px ≥ `ARROW_LEN_LABELLED (140)` ✓
- Vertical spacing between successive messages: 60px minimum to keep labels from colliding (80px is more comfortable)

**Numbered messages** (auth flow example): `1. /login`, `2. 302 -> IdP`, `3. authn`, `4. code`, `5. token exchange`, `6. id_token + access_token`, `7. set session cookie`, `8. /api/me + Bearer`, `9. 200 OK`.

**Colours:**
- User actor header: `#a5d8ff` (with `#4a9eed` border)
- Browser actor header: `#b2f2bb` (with `#22c55e` border)
- Backend actor header: `#d0bfff` (with `#8b5cf6` border)
- IdP actor header: `#ffd8a8` (with `#f59e0b` border)
- Resource API header: `#fff3bf` (with `#f59e0b` border)
- Successful messages: solid arrow, `#1e1e1e`
- Token / credential messages: solid arrow, `#8b5cf6`
- Async returns: dashed arrow, `#f59e0b`

**Camera plan:**
1. Camera M (600×450) on the title
2. Camera M zooming into each actor column right-to-left as you draw the headers and lifelines
3. Camera L (800×600) panning down the message sequence
4. Camera XL (1200×900) final overview

---

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

**Spacing budget (Camera XL 1200×900, 3 nested zones):**

- Outer zone (Public Internet): `(60, 60)` to `(1140, 840)`, padding `GAP_ZONE_INNER = 40` from each edge
- Each inner zone is offset by 40 from the outer (zone padding) plus 60 between sibling zones (`GAP_ZONE_OUTER`)
- DMZ row: occupies `y = 130` to `y = 250` (a strip across the top)
- App subnet: `y = 350` to `y = 530`
- Data subnet: `y = 630` to `y = 800`
- Inside each subnet, shapes use the same row/column spacing as the architecture overview (`GAP_SHAPE_H = 80`, `GAP_SHAPE_V = 100`)

Every arrow that crosses a zone gets a label describing the **trust transition**: `JWT validated`, `mTLS`, `managed identity`, `private endpoint only`. These labels need horizontal room — keep crossing arrows ≥ `ARROW_LEN_LABELLED (140)`.

**Camera plan:**
1. Camera L on the full layout (initial)
2. Camera M zooming into each ingress point in turn to highlight the validation step
3. Camera XL (1200×900) at the end for the panorama

---

## 4. Data flow

**Goal:** trace one record from its source to its sink.

**Layout:** left-to-right linear flow with branches. Each shape is a processing stage; each arrow is the record moving (with the schema name on the label).

```
[Webhook] -> [Validate] -> [Enrich] -> [Topic: orders.v1] -> [Worker] -> [Postgres: orders]
                                                  |
                                                  +--> [Audit log: blob://orders/audit/]
```

**Spacing budget (Camera XL 1200×900, 6-stage horizontal flow):**

- Stage shape `SHAPE_MIN_W × SHAPE_MIN_H` (160×70), `GAP_SHAPE_H = 80` gap
- Total row width: `6*160 + 5*80 = 1360` — too wide for Camera XL (drawable 1080)
- **Two options:**
  - (a) **Use the Landscape recipe** (paired Camera L panning) — recommended for >5 stages
  - (b) Wrap to two rows of 3 stages each, joined by a single down-then-right arrow
- Branch (audit log) sits 100px below the main row at the branch point, connected by a labelled arrow

**Colours:**
- Producer / source: `#a5d8ff`
- Transform / validate: `#fff3bf`
- Async hop (queue/topic): `#ffd8a8` with **diamond** shape
- Sink / store: `#c3fae8`
- Side effect: `#eebefa`

Label every arrow with the **schema or payload name and version** — `orders.v1`, not `data`.

**Camera plan:**
1. Camera M on the title
2. Landscape recipe: paired Camera L panning across the full pipeline
3. Camera XL final overview

---

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

**Spacing budget:** same as the security model (zones at `GAP_ZONE_INNER = 40` padding, `GAP_ZONE_OUTER = 60` between siblings). For multi-region topologies, use side-by-side region blocks separated by **at least** 100px and joined by labelled dashed arrows (`async replication`, `synchronous`, `DR only`).

**Camera plan:**
1. Camera L on the cloud-level wrapper
2. Camera M zooming into each region in turn
3. Camera XL for the final panorama (especially for multi-region)

---

## 6. Sequence flow

**Goal:** time-ordered "what happens when X" walkthrough.

This is the same shape as the auth flow diagram but for arbitrary actors. Reuse the auth-flow blueprint above with the same spacing budget (`GAP_ACTOR_COL = 220` between columns, 60–80px between successive messages).

When to use over a flow chart: when the answer to "what does this do" depends on **the order** of operations. Webhook handling, retries, async callbacks, distributed transactions.

---

## 7. Module dependency

**Goal:** show how internal packages depend on each other.

**Layout:** force-directed graph is unreadable in Excalidraw. Use a **layered DAG** instead:

- Layer 0 (top): public APIs / entry points
- Layer 1: feature modules
- Layer 2: shared libraries
- Layer 3 (bottom): platform / utility packages

Arrows point from the dependent to the dependency (i.e. downward). Every arrow that points **upward** is a layering violation and should be drawn in red.

**Spacing budget (Camera XL 1200×900, 4 layers):**

- Drawable height: 780. With 4 layers each `SHAPE_MIN_H (70)` and `GAP_LAYER (140)` between, total `4*70 + 3*140 = 700`. Top margin of 40 → bottoms at 110, 320, 530, 740. ✓
- Within each layer, columns at `GAP_SHAPE_H (80)` apart. For ≤6 modules per layer this fits in 1080 width.

**Colours:**
- Public surface: `#a5d8ff`
- Feature modules: `#d0bfff`
- Shared libraries: `#fff3bf`
- Utility packages: `#c3fae8`
- Layering violations: `#ef4444` arrow + `#ffc9c9` highlight on the violating shape

---

## Universal layout rules

These apply to every diagram type. Reference the spacing constants in [`excalidraw-style-guide.md`](excalidraw-style-guide.md#spacing-constants--hard-rules) by name.

| Rule | Constant / value |
|------|------|
| Minimum shape size | `SHAPE_MIN_W × SHAPE_MIN_H` (160 × 70) |
| Minimum horizontal gap between shapes | `GAP_SHAPE_H` (80) |
| Minimum vertical gap between shapes | `GAP_SHAPE_V` (100) |
| Minimum gap between layers | `GAP_LAYER` (140) |
| Minimum gap between sequence-diagram actor columns | `GAP_ACTOR_COL` (220) |
| Minimum padding inside a trust zone | `GAP_ZONE_INNER` (40) |
| Minimum gap between adjacent zones | `GAP_ZONE_OUTER` (60) |
| Minimum canvas margin | `MARGIN_CANVAS` (60) |
| Minimum labelled arrow length | `ARROW_LEN_LABELLED` (140) |
| Minimum body fontSize (inline) | 16 |
| Minimum title fontSize (inline) | 20 |
| Camera ratios | 4:3 only — for landscape, see the Landscape recipe in `excalidraw-style-guide.md` |
| Stream order | Background zones first, arrows last (z-order = array order) |
| Trust boundary opacity | Always 30 |

If a layout cannot fit at these values in your chosen camera, **use a bigger camera** — never break a constant.

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
