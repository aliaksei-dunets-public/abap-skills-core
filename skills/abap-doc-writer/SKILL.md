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
or just a bare method name with the class already known from context). Set
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
