# Export Schema

This file is the **wire-format contract** for `export_to_excalidraw`. It exists because the inline render and the export use different validators, and the difference has burned us repeatedly. Read it before any export call. It is not optional.

> **Read this section first, every time.** The single biggest reason exported diagrams come back as empty boxes is text elements that are missing required schema fields. If you remember nothing else, remember the text element schema below.

## Inline vs export — the validation divergence

`create_view` and `export_to_excalidraw` accept the **same JSON shape but apply different validators**. This is the gotcha that produces "renders fine in chat, exports as empty boxes".

- **`create_view` is lenient.** If a text element is missing `fontFamily`, `width`, `height`, `baseline`, `lineHeight`, `containerId`, or `originalText`, the MCP fills in defaults before drawing. The render looks correct in the conversation.
- **`export_to_excalidraw` is strict.** It pushes your JSON literally to `excalidraw.com`, which refuses to render any text element missing the fields above. Shapes survive; text vanishes; the diagram is unusable.

Both of the obvious workarounds **also** fail:

| Approach | Inline render | Export |
|---|---|---|
| Inline `label: { text: "..." }` shortcut on a shape | works | text dropped |
| Minimal standalone text (`type, id, x, y, text, fontSize, strokeColor` only) | works | text dropped |
| Standalone text with the **full schema** below | works | works |

Only the third row survives the round-trip. Use it.

## Required schema per element type

These are the minimum field sets that survive `export_to_excalidraw`. They have been verified end-to-end against `excalidraw.com`. Anything not listed here is droppable (see below).

### Rectangle

```json
{
  "type": "rectangle",
  "id": "<unique>",
  "x": 0, "y": 0, "width": 0, "height": 0,
  "strokeColor": "#hex",
  "backgroundColor": "#hex or transparent",
  "fillStyle": "solid",
  "strokeWidth": 2,
  "strokeStyle": "solid",
  "opacity": 100,
  "roundness": {"type": 3}
}
```

`roundness` is `null` for sharp corners. `strokeStyle` is `"solid"`, `"dashed"`, or `"dotted"`. `opacity` is 0–100 — use ~30 for trust-zone backgrounds (see [excalidraw-style-guide.md](excalidraw-style-guide.md#colour-assignments-architecture-specific)).

### Ellipse

```json
{
  "type": "ellipse",
  "id": "<unique>",
  "x": 0, "y": 0, "width": 0, "height": 0,
  "strokeColor": "#hex",
  "backgroundColor": "#hex or transparent",
  "fillStyle": "solid",
  "strokeWidth": 2
}
```

### Text — the one that matters

```json
{
  "type": "text",
  "id": "<unique>",
  "x": 0, "y": 0,
  "width": <int>, "height": <int>,
  "strokeColor": "#hex",
  "text": "Hello\nWorld",
  "fontSize": 14,
  "fontFamily": 5,
  "textAlign": "left",
  "verticalAlign": "top",
  "baseline": <int ≈ fontSize * 0.85>,
  "containerId": null,
  "originalText": "Hello\nWorld",
  "lineHeight": 1.25
}
```

**Every field above is load-bearing for export.** Drop any one of them and the text disappears in `excalidraw.com` while still rendering inline. The most common omissions:

| Field | Default Excalidraw expects | If missing |
|---|---|---|
| `fontFamily` | `5` (Excalifont). Also `1` Virgil, `2` Helvetica, `3` Cascadia | text not rendered |
| `width`, `height` | numeric | text renders at 0×0 (invisible) |
| `text`, `originalText` | identical strings | text dropped — `originalText` is the editing copy |
| `textAlign`, `verticalAlign` | `"left"`, `"top"` | text positioning breaks |
| `baseline` | `int(fontSize * 0.85)` | text positioning breaks |
| `containerId` | `null` for standalone | binding lookup fails |
| `lineHeight` | `1.25` | line wrapping breaks |

Width estimation: `int(max(len(line) for line in text.split("\n")) * fontSize * 0.6) + 20`
Height estimation: `int(len(text.split("\n")) * fontSize * 1.25) + 5`

These estimates are intentionally generous — under-sized boxes clip the text on export.

### Arrow

```json
{
  "type": "arrow",
  "id": "<unique>",
  "x": 0, "y": 0, "width": <dx>, "height": <dy>,
  "strokeColor": "#hex",
  "strokeWidth": 2,
  "strokeStyle": "solid",
  "points": [[0, 0], [<dx>, <dy>]],
  "endArrowhead": "arrow"
}
```

`points` is an array of `[dx, dy]` offsets from `(x, y)`. The first point is always `[0, 0]`. `endArrowhead` is `"arrow"`, `"bar"`, `"dot"`, `"triangle"`, or `null`.

### Fields you can safely omit

Tested as droppable across all element types. Excalidraw fills these in on import:

`angle`, `roughness`, `groupIds`, `frameId`, `boundElements`, `updated`, `link`, `locked`, `seed`, `version`, `versionNonce`, `isDeleted`, `lastCommittedPoint`, `startBinding`, `endBinding`, `startArrowhead`.

Including them is harmless but eats bytes. **Removing them is what gets a 100-element diagram under the bash output cap so you can `cat` the file and pass it to `export_to_excalidraw` in one round** — see the size budget below.

## Builder template — the verified recipe

Writing 100+ elements of full-schema JSON by hand is impractical. The error rate is too high and the user runs out of patience before you find your typos. The recipe that works is a Python heredoc piped to a file, then `cat` into the export call.

Copy this template, adapt the element list, run it via `python3 << 'PY'` from the Bash tool.

```python
import json
E = []

def R(id, x, y, w, h, bg="transparent", st="#1e1e1e", sw=2, ss="solid", op=100, rnd=True):
    el = {"type":"rectangle","id":id,"x":x,"y":y,"width":w,"height":h,
          "strokeColor":st,"backgroundColor":bg,"fillStyle":"solid",
          "strokeWidth":sw,"strokeStyle":ss,"opacity":op}
    if rnd: el["roundness"] = {"type": 3}
    E.append(el)

def L(id, x, y, w, h, bg="transparent", st="#1e1e1e", sw=2):
    E.append({"type":"ellipse","id":id,"x":x,"y":y,"width":w,"height":h,
              "strokeColor":st,"backgroundColor":bg,"fillStyle":"solid","strokeWidth":sw})

def T(id, x, y, txt, fs=14, c="#1e1e1e"):
    lines = txt.split("\n")
    w = int(max(len(l) for l in lines) * fs * 0.6) + 20
    h = int(len(lines) * fs * 1.25) + 5
    E.append({"type":"text","id":id,"x":x,"y":y,"width":w,"height":h,
              "strokeColor":c,"text":txt,"fontSize":fs,"fontFamily":5,
              "textAlign":"left","verticalAlign":"top",
              "baseline":int(fs * 0.85),"containerId":None,
              "originalText":txt,"lineHeight":1.25})

def A(id, x, y, w, h, pts, c="#1e1e1e", sw=2, ss="solid"):
    E.append({"type":"arrow","id":id,"x":x,"y":y,"width":w,"height":h,
              "strokeColor":c,"strokeWidth":sw,"strokeStyle":ss,
              "points":pts,"endArrowhead":"arrow"})

# Sequence-step marker = filled circle + number text. Reuse for numbered flows.
def NUM(id, cx, cy, num, color="#4a9eed"):
    L(id+"c", cx-15, cy-15, 30, 30, bg=color, st=color)
    T(id+"t", cx-5 if num<10 else cx-10, cy-10, str(num), fs=15, c="#0e0e1a")

# === BUILD YOUR DIAGRAM HERE ===
# R(...) for shapes, T(...) for text, A(...) for arrows,
# L(...) for ellipses, NUM(...) for numbered flow markers.

doc = {
    "type": "excalidraw",
    "version": 2,
    "source": "https://excalidraw.com",
    "elements": E,
    "appState": {"viewBackgroundColor": "#ffffff", "gridSize": None},
    "files": {}
}
print(json.dumps(doc, separators=(",", ":")))
```

## End-to-end recipe

```bash
# 1. Generate the JSON via the Python builder. Pipe to a file.
python3 << 'PY' > /tmp/diagram.json
import json
# ... builder helpers + your element definitions ...
print(json.dumps(doc, separators=(",", ":")))
PY

# 2. Verify the size — must fit the bash output cap (~32 KB) so you can cat it
echo "BYTES: $(wc -c < /tmp/diagram.json)"

# 3. Cat the file to dump the JSON into your context
cat /tmp/diagram.json
```

Then call `export_to_excalidraw` with the JSON content from step 3 as the `json` parameter.

### Size budget

The bash output cap is **~32 KB**. If `wc -c` reports more than that, the `cat` will be truncated and the export call will be malformed. Trim by, in this order:

1. **Drop optional fields** from the builder helpers — see "Fields you can safely omit" above. This is the cheapest reduction.
2. **Combine multi-line per-shape text** into a single `T(...)` call instead of separate title/body text elements. Roughly halves the text-element count.
3. **Reduce the diagram** to its load-bearing components and re-run.

The reference production diagram (109 elements, full deployment topology + numbered auth flow) lands at 29.5 KB after step 1. That is your headroom.

## The 2-element smoke test

Before generating a 100-element file in a fresh conversation, verify the schema is still working with the minimal test below. If text appears in the exported URL, the full-schema approach is healthy. If text is missing, something has changed in the MCP server or in `excalidraw.com` and you need to investigate before generating anything large.

```json
{
  "type": "excalidraw",
  "version": 2,
  "source": "https://excalidraw.com",
  "elements": [
    {
      "type": "rectangle", "id": "test_r1",
      "x": 100, "y": 100, "width": 400, "height": 150,
      "strokeColor": "#4a9eed", "backgroundColor": "#1e3a5f",
      "fillStyle": "solid", "strokeWidth": 2, "strokeStyle": "solid",
      "opacity": 100, "roundness": {"type": 3}
    },
    {
      "type": "text", "id": "test_t1",
      "x": 120, "y": 150, "width": 360, "height": 35,
      "strokeColor": "#e5e5e5",
      "text": "FULL SCHEMA TEXT TEST",
      "fontSize": 28, "fontFamily": 5,
      "textAlign": "left", "verticalAlign": "top",
      "baseline": 24, "containerId": null,
      "originalText": "FULL SCHEMA TEXT TEST",
      "lineHeight": 1.25
    }
  ],
  "appState": {"viewBackgroundColor": "#0e0e1a", "gridSize": null},
  "files": {}
}
```

Pass it to `export_to_excalidraw`, open the URL, and look for the text inside the box. If the text is visible, you are clear to proceed with the full diagram. A 5-second smoke test is much cheaper than three rounds of debugging a 100-element diagram.

## Verifying the export — never trust the inline render alone

`create_view` will render the same minimal text elements that fail on export. **The inline render is not proof that the export will work.** They use different validators and they fail differently.

The verification rule is: **always export, always open the URL, always confirm text is visible before declaring the diagram done.** The inline render is for the conversation; the export is what the user shares; treat them as two separate artefacts.

If the user is going to share the URL, the URL is the artefact that matters. Verify it.

## Don'ts

- Do not pass `label: { ... }` shortcuts to `export_to_excalidraw`. They render in `create_view` and disappear in the export. The shortcut is a `create_view` convenience, not part of the wire format
- Do not pass minimal standalone text (just `text` + `fontSize` + `strokeColor`) to `export_to_excalidraw`. It also gets dropped — use the full schema above
- Do not assume the inline render proves the export will work. They use different code paths and different validators
- Do not write 100 elements of full-schema JSON by hand. Use the Python heredoc — the typo rate on hand-written JSON is too high to be practical
- Do not skip the 2-element smoke test on a fresh conversation — the MCP server may have changed since the last successful run
- Do not declare a diagram done until you have opened the exported URL and seen the text with your own eyes
