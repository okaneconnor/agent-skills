# Jira Wiki Markup Reference

This reference covers the formatting conversion from Markdown to Jira Wiki Markup used by Atlassian Cloud Jira.

## Quick Conversion Table

| Element | Markdown | Jira Wiki Markup |
|---------|----------|------------------|
| Heading 2 | `## Heading` | `h2. Heading` |
| Heading 3 | `### Heading` | `h3. Heading` |
| Heading 4 | `#### Heading` | `h4. Heading` |
| Bold | `**bold**` | `*bold*` |
| Italic | `*italic*` | `_italic_` |
| Inline code | `` `code` `` | `{{code}}` |
| Link | `[text](url)` | `[text\|url]` |
| Bullet list | `* item` | `* item` |
| Numbered list | `1. item` | `# item` |
| Code block | `` ```lang ... ``` `` | `{code:lang}...{code}` |
| Table header | `\| H1 \| H2 \|` | `\|\|H1\|\|H2\|\|` |
| Table row | `\| C1 \| C2 \|` | `\|C1\|C2\|` |

## Headings

```
h1. Heading 1
h2. Heading 2
h3. Heading 3
h4. Heading 4
```

## Text Formatting

```
*bold text*
_italic text_
-strikethrough text-
+underline text+
{{monospaced text}}
```

## Lists

Unordered:
```
* Item 1
* Item 2
** Nested item
** Another nested item
* Item 3
```

Ordered:
```
# First item
# Second item
## Nested numbered item
# Third item
```

## Links

```
[Link text|https://example.com]
[Link text|https://example.com|Link title]
```

## Code Blocks

Without language:
```
{code}
some code here
{code}
```

With language:
```
{code:python}
def hello():
    print("Hello World")
{code}
```

## Tables

```
||Header 1||Header 2||Header 3||
|Cell 1|Cell 2|Cell 3|
|Cell 4|Cell 5|Cell 6|
```

## Important Notes

- The `post-to-jira.py` script handles Markdown-to-Jira conversion automatically when posting
- When writing drafts as `.md` files, use standard Markdown (the script converts it)
- When writing content that will go directly into Jira (e.g. via the UI), use Jira Wiki Markup
- Tables using `||header||` and `|cell|` syntax are already in Jira format and are preserved as-is by the script
