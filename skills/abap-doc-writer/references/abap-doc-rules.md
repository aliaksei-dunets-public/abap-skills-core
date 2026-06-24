# ABAP Doc Rules

Reference for generating and updating `"!` ABAP Doc comments. Read this file at the start of Phase 4.

---

## 1. Comment Syntax

Every ABAP Doc line starts with `"!` (no space before `!`).

A doc block is one or more consecutive `"!` lines placed **immediately before** a declaration statement — no blank ABAP lines between the block and the declaration.

Empty `"!` lines (just `"!` with no text) are valid and used for visual separation between the free-text description and `@` tag sections.

---

## 2. Supported Tags

Only these three tag types are valid ABAP Doc — no others exist in the spec:

| Tag | Covers | Position in block |
|-----|--------|-------------------|
| `"! @parameter <name> \| <desc>` | IMPORTING / EXPORTING / CHANGING / RETURNING parameters | After free-text description |
| `"! @raising <name>   \| <desc>` | Class-based exceptions (RAISING clause) | After `@parameter` tags |
| `"! @exception <name> \| <desc>` | Classic exceptions (EXCEPTIONS clause) | After `@parameter` tags |

**Tags not in the spec (never generate):** `@since`, `@todo`, `@throwing`, `@return`, `@returns`.

Tag lines: `@parameter`, `@raising`, `@exception` must start **directly after `"! `** — no leading spaces after the prefix.

Each parameter / exception name must appear at most once per block.

---

## 3. Alignment Rule

All `|` separators within one method's doc block must align to the same column.
Column = longest parameter/exception name + 2 spaces.

**Example — correct alignment:**

```abap
"! Checks if two sources are identical.
"!
"! @parameter source1     | First source
"! @parameter source2     | Second source
"! @parameter ignore_case | Pass abap_true to ignore case
"! @parameter result      | Returns abap_true if sources are identical
"!
"! @raising   cx_invalid_source
"!                        | One of the sources is empty
```

For long exception/class names that exceed the column, the description moves to the **next `"!` line** indented to the same `|` column.

---

## 4. Smart Update Rules

Apply these rules for every declaration that already has a `"!` block:

| Situation | Action |
|-----------|--------|
| No `"!` block exists | Generate full new block |
| Block exists, no free-text description | Add one-sentence description |
| Block exists, description present, NOT update mode | **Preserve** — do not touch |
| Block exists, description present, update mode | Rewrite with new generated description |
| `@parameter` tag missing for a parameter in signature | **Append** tag in correct position |
| `@parameter` tag present for a parameter **removed** from signature | **Remove** tag |
| `@parameter` tag present, description exists | Preserve description as-is |
| `@raising` / `@exception` — same rules as `@parameter` | Same as above |
| `{@link ...}` reference anywhere in existing block | **Always preserve** — never remove or rewrite |
| `<p class="shorttext ...">` paragraph in existing block | **Always preserve** — never remove or rewrite |

After any structural change (add/remove tags), **recalculate** the `|` alignment column for the whole block.

---

## 5. Description Generation Guidelines

When generating a new description (no existing text, or update mode):
- One sentence maximum for methods; two sentences allowed for class/interface level.
- Derive from: method name, parameter names, return type, exception names.
- Be factual — describe what the signature implies; do not invent behavior.
- Write in the language configured in `doc_language` (default: EN).
- Start with a verb in the third person singular present: "Returns …", "Adds …", "Validates …", "Creates …".

---

## 6. HTML Formatting Tags (valid in free-text description)

These HTML tags may appear in description text and must be preserved when already present:

`<h1>`, `<h2>`, `<h3>`, `<p>`, `<em>`, `<strong>`, `<ul>`, `<ol>`, `<li>`, `<br>`

Open tags must be closed **before** a `@parameter`/`@raising`/`@exception` section begins.

---

## 7. Short Text Synchronization

```abap
"! <p class="shorttext synchronized" lang="EN">Short description here.</p>
```

When `shorttext_synchronized: true` in config, add this as the **first line** of every newly generated class, interface, or method doc block. Max 40 characters for method short texts.

Always preserve this line if already present in an existing block — even in update mode.

---

## 8. Documentation Links (`{@link}`)

```
{@link cl_some_class}
{@link cl_some_class.METH:some_method}
{@link .METH:local_method.DATA:param}
```

`{@link ...}` tokens may appear anywhere in free-text description lines. Always preserve them. Never generate new `{@link}` references — only the developer knows the correct link targets.

---

## 9. Special Character Escaping

When generating any description text, escape these characters:

| Char | Escape |
|------|--------|
| `"` | `&quot;` |
| `'` | `&apos;` |
| `<` | `&lt;` |
| `>` | `&gt;` |
| `@` | `&#64;` |
| `{` | `&#123;` |
| `\|` | `&#124;` |
| `}` | `&#125;` |

---

## 10. Chained Statements

For `DATA: BEGIN OF struct, comp1 TYPE i, comp2 TYPE i, END OF struct` — ABAP Doc comments go **immediately before each identifier** within the chain, not before the `DATA:` keyword.

---

## 11. Class and Interface Level Doc

Place one `"!` block immediately above `CLASS <name> DEFINITION` or `INTERFACE <name>`.

Generate only when absent. Never overwrite an existing class/interface-level block.

Template for a new class block:
```abap
"! <Description sentence derived from class name and purpose.>
CLASS zcl_example DEFINITION
```

Template for a new interface block:
```abap
"! <Description sentence derived from interface name and purpose.>
INTERFACE zif_example
```
