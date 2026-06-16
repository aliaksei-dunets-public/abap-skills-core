---
name: abap-wiki-doc-creator
description: >
  Use after completing an ABAP development feature to generate a self-contained
  HTML wiki page documenting the feature. Trigger on: "create wiki", "generate
  documentation", "document this feature", "create wiki for package/TR/commit",
  or any mention of documenting ABAP development artifacts.
---

# ABAP Wiki Doc Creator

Generates a self-contained HTML wiki page for an ABAP feature. Collects artifacts
from one or more sources, lets the user confirm scope, reads source code, and
produces a styled `.wiki.html` file in the configured output folder.

---

## Inputs

Parse `$ARGUMENTS` and the conversation for the following:

| Input | Detection |
|---|---|
| **Package** | Token matching `package:<NAME>` or `pkg:<NAME>` or a bare package name starting with namespace prefix |
| **Transport Request** | Token matching `TR:<ID>` or format `<3-char>K<6-digit>` e.g. `H01K123456` |
| **Git ref** | Token matching `git:<ref>` or a git commit hash / branch name |
| **Object list** | Comma-separated list of two or more ABAP object names |
| **Previous wiki** | Path ending in `.wiki.html` — triggers UPDATE mode |
| **Additional instructions** | All remaining free text after source tokens |

If none of the source tokens are detected and no object list is present, ask:
> "Please provide at least one source: a package name, transport request (e.g. `H01K123456`), git ref (e.g. `git:abc1234`), or a list of object names."

---

## Phase 1 — COLLECT

Load config:
1. Read `configs/config.md`. Extract `output_path` (default: `docs/wiki`).
2. Read `references/object-sort-order.md` — keep in context for Phase 2 and 3.

Collect objects from each provided source:

### Git ref source

```bash
git diff --name-only <ref>
# or for a single commit:
git show --name-only --format="" <ref>
```

Filter paths that correspond to ABAP objects (paths containing `.adt/`, `.aclass`, `.asddls`, `.asbdef`, `.acinc`, etc.). Extract object names by parsing the path's encoded segment (reverse-apply URL decoding from `references/object-sort-order.md`).

### Package source

Use `abap-tools` MCP: call the list-package-objects tool with the package name.
Each returned object has name, type, and package fields.

### Transport Request source

Use `abap-tools` MCP: call the list-transport-objects tool with the TR number.
Each returned object has name, type, and package fields.

### Object list source

Parse the comma-separated names. Infer type from name prefix (e.g. `ZI_` → DDLS, `ZCL_` / `ZBP_` → CLAS, `ZC_` → DDLS, etc.) or ask the user if ambiguous.

### UPDATE mode

When a previous wiki path is provided:
1. Read the existing wiki file.
2. Parse the *Development Artifacts (Full List)* table to extract the previous object list.
3. Run COLLECT on new sources to get the updated object list.
4. Diff old vs new: tag each object as `added`, `removed`, or `unchanged`.
5. In Phase 3, only read sources for `added` objects (and flag `removed` ones in the table).
6. In Phase 4, regenerate only sections that reference changed objects; copy unchanged sections verbatim from the previous wiki.

### Normalize and deduplicate

Apply sort order from `references/object-sort-order.md`:
1. Map each object to its canonical type code (DDLS, BDEF, CLAS, TABL, …).
2. Sort by type order number, then alphabetically within the same type.
3. Deduplicate: if the same object appears in multiple sources, merge into one entry with all sources listed.

Output: unified list `{ #, name, type, package, source }`.

If the unified list is empty after deduplication, display:
> "No ABAP objects found in the provided source(s). Please provide a different source or a manual comma-separated object list."
And stop — do not proceed to Phase 2.

---

## Phase 2 — SHOW LIST

Display the unified object list as a table:

```
Found <N> objects. Please confirm the scope:

  #  | Type | Name                        | Package    | Source
  ---|------|-----------------------------|------------|--------
   1 | DDLS | ZI_SalesOrder               | ZSALES     | package
   2 | DDLS | ZC_SalesOrder               | ZSALES     | package
   3 | CLAS | ZCL_SO_Validator            | ZSALES     | TR:H01K123456
  ...

Commands:
  ok                    — confirm and proceed
  exclude <nums>        — remove objects, e.g. "exclude 4,7"
  note <num>: <text>    — add annotation to an object, e.g. "note 3: main validator"
```

Wait for the user's response before proceeding.

After confirmation, if `FeatureName` was not supplied in `$ARGUMENTS`, propose one based on the main object (e.g. the root CDS view or the top-level class):

> "Suggested feature name: `SalesOrder`. This will be used in the output filename. Accept or provide a different name?"

Wait for the user's response. Use the confirmed name as `<FeatureName>` for the output file.

---

## Phase 3 — READ SOURCES

Read `references/source-reader.md` and follow the detection chain for each object in sort order.

**On cache miss** (abap-vs-reader returns MISSING):

Construct the ADT virtual path using the type → URI type-label and filename mapping from `.claude/skills-core/skills/abap-vs-reader/SKILL.md` (Step 2.3.5). Then display:

```
⚠ Object not found in ADT cache: <OBJECT_NAME> (<TYPE>)

Please open it in VS Code using this ADT path:
  /repotree-v1/<SYSTEM_ID>/<ROOT_SEGMENT>/<TOP_PACKAGE>/.../<TYPE_LABEL>/<OBJECT_NAME>

Or click its node in the ADT Project Explorer tree.

Send any message when the file is open.
```

After user responds → retry read once. If still missing → mark the object with `⚠ source unavailable` in Phase 4 tables. Continue with next object.

**READ order within types:**

For classes (CLAS): read `.aclass` first (signature), then `implementations.acinc`, then `definitions.acinc`. Skip `testclasses.acinc` — test code is not documented in wiki.

For BDEF: read the single `.asbdef` file.

For CDS (DDLS): read the single `.asddls` file.

For TABL: read the `.tabl` file — contains field list and key definitions.

For SRVB: skip source read (XML only). List in artifacts table but mark as `(XML metadata only)`.

---

## Phase 4 — GENERATE

Read `references/html-template.md` for the HTML shell, section structure, and formatting conventions.
Read `references/diagram-guide.md` for PlantUML templates.

Build the HTML wiki page section by section:

### 1. TOC
Use the template from `references/html-template.md`. All anchor `href="#id"` values must match the `id` attributes in the headings below.

### 2. Business Context
- Functional purpose: derive from user's additional instructions; if absent, summarize from the main CDS view or BDEF purpose.
- Business problem: from user instructions or infer from object naming/annotations.
- Developer notes `<div class="info">`: key technical decisions, integration points mentioned in instructions.

### 3. Technical Context

#### High-Level Design
- List building blocks as `h5` headings (one per major component group).
- If a BDEF is present: describe RAP hierarchy (BO root → projections → service).
- Source: object type analysis + annotations from Phase 2.

#### Application Flow Diagram
- Build PlantUML sequence diagram using the template from `references/diagram-guide.md`.
- Participants: derive from BDEF operations (actions, validations) and class method signatures.
- If no BDEF present: use a simple activity diagram showing the main class interactions.

#### Data Model

**CDS View Hierarchy:** build from `DEFINE VIEW EXTENDING` statements in DDLS sources. Show Basic → Composite → Consumption layers plus any Metadata Extensions.

**Database Table Model:** build from TABL sources. For each table: extract fields, mark key fields (`<<PK>>`), infer FK relations from JOIN conditions in CDS sources or explicit FK definitions in TABL source. Use entity diagram template from `references/diagram-guide.md`.

#### Class Diagram
- Build from INTF and CLAS sources using class diagram template from `references/diagram-guide.md`.
- Show: interfaces, implementing classes, behavior pools, inheritance, public method signatures.
- Omit private helper methods unless they are central to understanding the design.

#### Technical Details

*Development Details table:*
| Field | Value |
|---|---|
| Package | `<package from object list>` |
| Transport | `<TR number if provided>` |
| Namespace | `<derived from primary_namespace in project-config.md>` |
| System | `<system_id from abap-vs-reader configs/system.md>` |

*CDS Views table:* one row per DDLS object. Type column: Basic / Composite / Consumption / Extension — derived from `DEFINE VIEW`, `EXTEND VIEW`, and annotations in source.

*Development Artifacts (Full List) table:* one row per object in Phase 2 confirmed list. Columns: `Application Node Name` | `Type` | `Description`. Objects with `⚠ source unavailable` are listed but marked.

*Behavior Definition Operations Summary table:* only if at least one BDEF is present. Columns: `Entity` | `CRUD Operations` | `Actions` | `Validations` | `Determinations`. Derive from BDEF source.

*Message Class table:* only if at least one MSAG is present. Columns: `ID` | `Text` | `Usage`. Derive from MSAG source.

### 4. Process Flow
- Source reference: `TR: <number>` or `git: <ref>` or `pkg: <name>`.
- Step-by-step `<ol>` instructions: derive from user's additional instructions; if absent, write generic "how to extend this component" steps based on the RAP/class structure.
- Integration points: list other packages/services referenced in the source (JOIN targets, BAPI calls, interfaces implemented).

---

## Phase 5 — SAVE

1. Determine `output_path` from config (default: `docs/wiki`).
2. Create the folder if it does not exist.
3. Determine output filename: `YYYY-MM-DD-<FeatureName>.wiki.html` using today's date.
4. Write the generated HTML to the file.
5. Confirm to the user:

```
Wiki saved: docs/wiki/2026-06-16-SalesOrder.wiki.html
Objects documented: 11
Objects skipped (source unavailable): 1 — ZCL_LEGACY_ADAPTER
```

---

## UPDATE mode summary

When a previous wiki path is provided (detected in Phase 1):
- Show the diff between old and new object list in Phase 2 — clearly mark added/removed objects.
- In Phase 3: only read sources for new/added objects.
- In Phase 4: regenerate only sections that reference changed objects. Copy unchanged sections verbatim from the previous wiki HTML.
- Save with today's date — the previous wiki file is NOT overwritten.
