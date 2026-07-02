---
name: abap-wiki-doc-creator
description: >
  Use after completing an ABAP development feature to generate a self-contained
  HTML wiki page documenting the feature. Trigger on: "create wiki", "generate
  documentation", "document this feature", "create wiki for package/TR/commit",
  or any mention of documenting ABAP development artifacts.
---

# ABAP Wiki Doc Creator

Generates a self-contained HTML wiki page for an ABAP feature. Four linear phases:

```
COLLECT → READ → GENERATE(.wiki.md) → [user review] → SAVE(.wiki.html)
```

Both output files (`YYYY-MM-DD-<FeatureName>.wiki.md` and `.wiki.html`) are kept in `output_path`.

---

## Inputs

Parse `$ARGUMENTS` and the conversation context freely — no rigid token format required.
Recognise:

| Input | Detection |
|---|---|
| **Package** | Name starting with namespace prefix, or `package:<NAME>` / `pkg:<NAME>` |
| **Transport Request** | Format `<3-char>K<6-digit>` e.g. `H01K123456`, or `TR:<ID>` |
| **Git ref** | `git:<ref>`, commit hash, or branch name |
| **Object list** | Comma-separated ABAP object names |
| **Previous wiki** | Path ending in `.wiki.html` or `.wiki.md` — triggers UPDATE mode |
| **Extra files/docs** | Any other file paths or document references — read before ABAP objects |
| **FeatureName** | Explicit name in arguments — highest priority |

If no source is detected, ask:
> "Please provide at least one source: a package name, transport request (e.g. `H01K123456`), git ref (e.g. `git:abc1234`), or a list of object names."

---

## Phase 1 — COLLECT

Load config:
1. Read `configs/config.md`. Extract `output_path` (default: `docs/wiki`).
2. Read `references/object-sort-order.md` — keep in context for all phases.

Collect objects from each provided source:

### Package source
Use `abap-tools` MCP: call the list-package-objects tool with the package name.

### Transport Request source
Use `abap-tools` MCP: call the list-transport-objects tool with the TR number.

### Git ref source
```bash
git show --name-only --format="" <ref>
# or for a range:
git diff --name-only <ref>
```
Filter paths containing `.adt/`, `.asddls`, `.asbdef`, `.tabl`, `.prog`, etc.
Extract object names by parsing the path's encoded segment.

### Object list source
Parse the comma-separated names. Infer type from name prefix
(`ZI_` / `ZR_` / `ZC_` → DDLS, `ZCL_` / `ZBP_` → CLAS, etc.) or ask if ambiguous.

### Clarification conditions

Ask the user **only** when:
1. No source is provided at all
2. A source is ambiguous (e.g. name matches multiple packages)
3. Collected object count exceeds 100 — report the count and ask whether to narrow scope

### Normalise and deduplicate

1. Map each object to its canonical type code using `references/object-sort-order.md`
2. Sort by type order number, then alphabetically within type
3. Deduplicate: same object from multiple sources → one entry, all sources listed

### FeatureName resolution (priority order)
1. Explicit name from user arguments
2. Name from existing wiki filename (UPDATE mode)
3. Auto-derived from main object: root CDS view (`ZI_*` / `ZR_*`) or top-level class, strip namespace prefix

### UPDATE mode
Triggered automatically when a `.wiki.html` or `.wiki.md` path is in arguments.
See UPDATE MODE section at the end of this skill.

If the unified list is empty after collection, display:
> "No ABAP objects found in the provided source(s). Please provide a different source or a manual comma-separated object list."
And stop.

---

## Phase 2 — READ

### Read order
1. **Extra files and documents first** — they provide business/functional context that informs interpretation of all ABAP source
2. **ABAP objects** in sort order from `references/object-sort-order.md`

### Per-object read rules

| Type | What to read |
|---|---|
| DDLS | `.asddls` |
| DDLX | `.asddlxex` |
| BDEF | `.asbdef` |
| SRVD | `.assrvds` |
| SRVB | XML metadata only — no source read; list in artifacts table as `(XML metadata only)` |
| INTF | `.intf.abap` |
| CLAS | `.clas.abap` + `.clas.implementations.abap` + `.clas.definitions.abap` + `.clas.testclasses.abap` |
| TABL | `.tabl` |
| STRU | `.stru` |
| AUTH | `.auth` |
| ENQU | `.enqu` |
| DTEL | `.dtel` |
| DOMA | `.doma` |
| MSAG | `.prog.msag` |

For CLAS: invoke `abap-vs-reader` for `.clas.abap` first to resolve the virtual URI.
Once the URI is known, read `.clas.implementations.abap`, `.clas.definitions.abap`, and
`.clas.testclasses.abap` directly by substituting the filename suffix.

**Test classes contain valuable behaviour information and must not be skipped.**

### Fallback chain — no object is ever skipped

```
1. Direct read_file via virtual URI
        ↓ fails
2. Invoke abap-vs-reader skill
        ↓ fails
3. Ask user for help:
   - Open the file manually in their editor
   - Provide the path in their virtual workspace
   - Paste the source content directly
   - Any other means available to them

   → Wait for user response before continuing.
   → Do NOT proceed to GENERATE until all objects are resolved.
```

---

## Phase 3 — GENERATE

Read `references/html-template.md` for section structure and formatting conventions.
Read `references/diagram-guide.md` for PlantUML templates.

Write `YYYY-MM-DD-<FeatureName>.wiki.md` to `output_path`.

Build each section:

### 1. TOC
All anchor `href="#id"` values must match heading `id` attributes below.

### 2. Business Context
- Functional purpose: from user instructions; if absent, infer from main CDS view or BDEF annotations
- Business problem: from user instructions or infer from object naming
- Key technical decisions and integration points in an info block

### 3. Technical Context

#### High-Level Design
- Building blocks as h5 headings (one per major component group)
- If BDEF present: describe RAP hierarchy (BO root → projections → service)

#### Application Flow Diagram
- PlantUML sequence diagram using template from `references/diagram-guide.md`
- Derive participants from BDEF operations (actions, validations) and class method signatures
- If no BDEF: use activity diagram showing main class interactions

#### Data Model

**CDS View Hierarchy:** build from `DEFINE VIEW EXTENDING` in DDLS sources.
Show Basic → Composite → Consumption layers plus Metadata Extensions.

**Database Table Model:** build from TABL and STRU sources.
Fields, key fields (`<<PK>>`), FK relations from JOIN conditions in CDS or FK definitions in TABL/STRU.

#### Class Diagram
Build from INTF and CLAS sources. Show: interfaces, implementing classes, behavior pools,
inheritance, public method signatures. Include lock objects (ENQU) and auth objects (AUTH)
as notes if present.
Omit private helper methods unless central to understanding the design.

#### Technical Details

*Development Details:* Package (from object list) | Transport (TR if provided) | Namespace (`primary_namespace` from `project-config.md`) | System (`system_id` from `configs/system.md`)

*CDS Views table:* one row per DDLS. Type: Basic / Composite / Consumption / Extension.

*Development Artifacts (Full List) table:* columns: `Application Node Name` | `Type` | `Description`.
All objects from confirmed list, including STRU, AUTH, ENQU.

*Behavior Definition Operations Summary table:* only if BDEF present.
Columns: `Entity` | `CRUD Operations` | `Actions` | `Validations` | `Determinations`.

*Message Class table:* only if MSAG present. Columns: `ID` | `Text` | `Usage`.

### 4. Error Handling & Messages

*Exception classes:* `Class` | `Where raised` — derive from `RAISE`, `RAISE EXCEPTION`, `cx_` in all sources.
*Messages (MSAG only):* `ID` | `Text` | `Where raised`
If neither found: "No custom exception classes or message classes found."

### 5. Authorization

*Authority-check objects:* `Auth Object` | `Fields checked` | `Method / Operation` — derive from `AUTHORITY-CHECK OBJECT` in all sources. For AUTH objects in the artifact list, describe their fields.
If none found: "No explicit authority checks found in source."

### 6. Process Flow

- **Fiori Applications:** app IDs, tile descriptions, target mappings — from SRVB metadata or user docs
- **Implemented Functionality:** brief end-to-end description of what the feature does for the user
- **User Scenarios (for QA and end users):** numbered step-by-step flows, derived from BDEF operations,
  test class scenarios, and user instructions
- **Integration Points:** other packages/services referenced in source (JOINs, CALL FUNCTION, HTTP calls)
- **Source Reference:** `TR: <number>` or `git: <ref>` or `pkg: <name>`

### 7. Known Issues & Limitations

- Bulleted list of TODO/FIXME comments found in source code (include object name and context)
- Documented limitations from user-provided documents
- Known workarounds if mentioned in source or docs

If nothing found, write a single line: "No known issues or limitations documented."

---

### After writing the draft

Report to user:
```
Draft saved: <output_path>/YYYY-MM-DD-<FeatureName>.wiki.md
Objects documented: N
Please review the draft and confirm to generate HTML, or request changes.
```

Wait for user response:
- **Confirmed / approved** → proceed to Phase 4 (SAVE)
- **Changes requested** → apply edits to the `.md` file, re-report, wait again

---

## Phase 4 — SAVE

1. Re-read `references/html-template.md` and `references/diagram-guide.md`.
2. Generate HTML applying all conventions from those references.
3. Write `YYYY-MM-DD-<FeatureName>.wiki.html` to `output_path`.
4. Report:

```
Wiki saved:
  <output_path>/YYYY-MM-DD-<FeatureName>.wiki.md
  <output_path>/YYYY-MM-DD-<FeatureName>.wiki.html
Objects documented: N
```

---

## UPDATE MODE

### Trigger
Presence of a `.wiki.html` or `.wiki.md` path in arguments.

### Steps
1. Read the existing wiki file.
2. Parse the *Development Artifacts (Full List)* table to extract the previous object list.
3. Run COLLECT on new sources to get the current object list.
4. Determine which objects to re-read:

**If user explicitly listed changed objects** (e.g. `changed: ZCL_SO_Validator`):
- Read only those objects using the fallback chain
- Regenerate only sections that reference them
- Copy unchanged sections verbatim from the previous wiki

**Otherwise (default):**
- Re-read ALL objects using the fallback chain
- Compare current source against what was documented
- Tag each object as `added`, `removed`, `changed`, or `unchanged`
- Regenerate sections for `added` and `changed` objects only
- Copy unchanged sections verbatim
- Flag `removed` objects in the artifacts table

5. Run Phase 3 (GENERATE) and Phase 4 (SAVE) as normal.
6. Save with today's date — previous wiki file(s) are **not overwritten**.
7. Show diff summary after save:

```
Updated: <output_path>/YYYY-MM-DD-<FeatureName>.wiki.md
Objects: 15 total — 3 changed, 1 added, 1 removed, 10 unchanged
Changed: ZCL_SO_Validator, ZI_Order, ZC_Order
Added:   ZCL_NEW_HELPER
Removed: ZCL_LEGACY_ADAPTER
```
