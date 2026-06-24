---
name: abap-doc-writer
description: >
  Use to write or update ABAP Doc ("!) comment blocks in ABAP classes and
  interfaces. Trigger on: "write ABAP doc", "add ABAP Doc comments",
  "document this class/interface/method", "update ABAP Doc",
  "напиши ABAP Docu", "обнови ABAP Doc", or any request to add or refresh
  "! comments for methods, parameters, exceptions, or class-level descriptions.
  Never modifies ABAP logic — only inserts or updates "! comment lines.
---

# ABAP Doc Writer

Generates and smart-updates `"!` ABAP Doc comment blocks for ABAP classes and
interfaces. Reads source via `abap-vs-reader`. Writes back to the local
filesystem file resolved from the virtual URI. Never touches any non-`"!` line.

---

## Phase 1 — Load Config

Read `configs/config.md` if it exists (follow any `→ Read …` references inside it).

Extract these fields, applying defaults when absent:

| Field | Default | Effect |
|-------|---------|--------|
| `doc_language` | `EN` | Language for generated descriptions |
| `line_wrap` | `90` | Max characters per `"!` line |
| `document_private` | `true` | When false: skip private methods |
| `shorttext_synchronized` | `false` | When true: add `<p class="shorttext synchronized">` to new blocks |

---

## Phase 2 — Detect Input Mode

Parse `$ARGUMENTS` and the conversation. Detect mode in order — first match wins:

**Update mode flag:** the user's message contains any of: "update", "refresh",
"актуализируй", "обнови", "обновить". Set `UPDATE_MODE = true`. This flag is
independent of the object/method scope — it only controls whether existing
descriptions may be rewritten.

**Mode A — Method scope:** `$ARGUMENTS` contains one object name AND one or
more method names (e.g. "document `add_child_entity` in `/HEC4/CL_UPLD_RAP_ENTITY`",
or just a bare method name when the class name was established in the immediately preceding turn of the current conversation). Set
`METHOD_SCOPE` to the list of named methods. Proceed to Phase 3.

**Mode B — Single object:** `$ARGUMENTS` is a single ABAP class or interface
name. Set `METHOD_SCOPE = ALL`. Proceed to Phase 3.

**No match:** Ask exactly one question:
> "Please provide the ABAP class or interface name to document
> (e.g. `/HEC4/CL_UPLD_RAP_ENTITY`). You can also name specific methods."

Wait for the answer. Do not proceed until a name is provided.

---

## Phase 3 — Fetch Source

Invoke **`abap-vs-reader`** with the object name from Phase 2.

**For global ABAP classes** — once the main `.clas.abap` URI is resolved, read
sibling includes by substituting the filename suffix (same pattern as
`abap-code-review`):

| Include | Suffix | Purpose |
|---------|--------|---------|
| Main definition | `*.clas.abap` | `PUBLIC SECTION`, class header — **primary write target** |
| Local definitions | `*.clas.definitions.abap` | Additional `DEFINITION` blocks |
| Implementations | `*.clas.implementations.abap` | Read only — never written; used to infer method purpose if needed |

Record the **resolved local file path** for each include. These are the write
targets in Phase 5. If an include is empty or absent, skip it silently.

**For interfaces** — read `*.intf.abap` only. This is the single write target.

If `abap-vs-reader` cannot resolve the source:
1. Ask the user to confirm the object name or open it in VS Code.
2. Only after explicit confirmation that the object cannot be found, note
   `[SOURCE NOT FOUND]` and stop — do not proceed to Phase 4.

---

## Phase 4 — Parse & Generate

Read `references/abap-doc-rules.md` before this phase.

### Determine declarations in scope

Scan the source for all declaration statements that ABAP Doc may precede:
- `METHODS` in `PUBLIC SECTION`, `PROTECTED SECTION`, `PRIVATE SECTION`
  (all sections unless `document_private: false`, in which case skip `PRIVATE SECTION`)
- `CONSTANTS`, `DATA`, `TYPES`, `CLASS-DATA`, `CLASS-METHODS` in `PUBLIC SECTION`
- Interface methods in `INTERFACE` source
- Identifiers within chained `DATA:` / `TYPES:` blocks (see rules §10)

If `METHOD_SCOPE` is set (Mode A), process only the named methods. For all
other declarations, report `[OUT OF SCOPE]` — do not modify them.

### For each declaration in scope

1. **Find existing `"!` block** — the consecutive `"!` lines immediately
   preceding the declaration statement with no intervening non-`"!` lines.

2. **Parse the block** — extract:
   - Free-text description lines (all `"!` lines before the first `@` tag)
   - `@parameter`, `@raising`, `@exception` tags: name and description
   - `{@link ...}` tokens — record their exact position in the block
   - `<p class="shorttext ...">` paragraphs — record exact content

3. **Parse the method signature** — extract:
   - All parameter names and their clause (IMPORTING / EXPORTING / CHANGING / RETURNING)
   - All exceptions (RAISING → `@raising`; EXCEPTIONS → `@exception`)

4. **Apply smart update rules** from `references/abap-doc-rules.md` §4.

5. **Generate description** when needed, following §5 of the rules.
   Apply line wrapping at `line_wrap` characters.
   Apply special character escaping from §9 of the rules.

6. **Re-align** the `|` column across all `@parameter`/`@raising`/`@exception`
   tags in the new block, following §3 of the rules.

7. **Record status** for the report:
   - `[ADDED]` — declaration had no doc block; new block was generated
   - `[UPDATED]` — existing block was modified (tags added/removed, description rewritten in update mode)
   - `[SKIPPED]` — existing block is complete; no changes needed

### Class / interface level doc

Apply §11 of the rules: generate a one-block class/interface description above
`CLASS ... DEFINITION` or `INTERFACE` if absent. If already present, mark
`[SKIPPED]` and do not touch it.

---

## Phase 5 — Write Back & Report

> **CONSTRAINT:** This skill may only insert, replace, or remove lines that
> start with `"!`. Before writing any file, verify that every pending change
> touches only `"!` lines. If any change would alter a non-`"!` line, abort
> the write for that file, report the affected line(s) and their content, and
> stop. Do not attempt a partial write.

### Write back

Write back only `*.clas.abap` and `*.clas.definitions.abap` files. Never write
to `*.clas.implementations.abap` — it was read in Phase 3 for context only.

For each include file that has at least one `[ADDED]` or `[UPDATED]`
declaration:

1. Take the original source text.
2. Replace only the `"!` comment lines that were modified — preserve every
   other line exactly (character-for-character).
3. Write the full modified source back to the resolved local file path from
   Phase 3 using the file write tool.
4. If the write fails, report the error and leave that file unchanged. Do not
   attempt partial writes.

### Report

Print a summary in chat:

```
Object:  /HEC4/CL_UPLD_RAP_ENTITY
Written: C:\...\zcl_example.clas.abap

Methods & declarations:
  add_child_entity        [ADDED]
  get_entity_descr        [SKIPPED] — doc already complete
  constructor             [UPDATED] — added @parameter iv_name
  lc_helper~do_something  [ADDED]
  C_MAX_RETRIES (CONST)   [SKIPPED]
```

If no files were changed (all `[SKIPPED]`), report:
```
Object: /HEC4/CL_UPLD_RAP_ENTITY
No changes — all declarations already have complete ABAP Doc.
```
