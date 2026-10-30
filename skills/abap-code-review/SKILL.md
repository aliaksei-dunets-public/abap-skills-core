---
name: abap-code-review
description: >
   Use when reviewing ABAP objects, packages, transport requests, or transport tasks
   before release or handoff. Trigger on: "review this ABAP", "check this class/CDS/behavior
   definition", "code review for transport", pasted ABAP/CDS source code, or any request
   to find defects, inconsistencies, dead code, duplicate logic, outdated code, contract
   risks, weak tests, or architecture issues in ABAP-related artifacts.
---

# ABAP Code Review

Evidence-based ABAP solution review. Architecture-first, rule files as second pass. Output: severity-graded findings table, optional architecture leads, optional suggested tests, release gate verdict per object. Assessment only — no fixes.

---

## Phase 1 — Load Config and Resolve Categories

Read `configs/config.md` if it exists; follow any `→ Read …` references inside it.

Default to all categories when no filter is configured.

### Categories — internal only

The codes below drive the rule-file pass in Phase 5 and dedup in Phase 5.5. **They must not appear in the final report** — no `Rule:` attribute inside findings, no `## Rule coverage` section, no category code in table cells or card fields. See `references/reporting-format.md` § *Prohibited elements*.

The first block is **static rules** (concrete IDs, applied in Phase 5.a). The second block is **review lenses** (reasoning heuristics, applied in Phase 5.b — no rule IDs). Lens findings must name the concrete defect / risk / waste in the finding text.

| Code | Purpose | Reference |
|------|---------|-----------|
| `ARCH` | Architecture, duplicate/dead/outdated code, risky assumptions | `references/best-practices.md` |
| `PERF` | Performance and SQL risks | `references/rules-performance.md` |
| `CLEAN` | Clean ABAP issues | `references/rules-clean-abap.md` |
| `NAME` | Naming rules | `references/naming-convention.md` |
| `RAP` | RAP correctness | `references/rap-review.md` |
| `CDS` | CDS architecture rules | `references/rules-cds.md` |
| `CCORE` | Clean Core risks | `references/clean-core.md` |
| `TEST` | Testability issues | `references/rules-testability.md` |
| `TESTSUG` | Suggested additional tests | `references/best-practices.md` |
| `DOC` | Documentation issues | `references/rules-documentation.md` |
| `LOGIC` | Hidden logical errors — reasoning lens | `references/lens-logic.md` |
| `RUNTIME` | Short-dump / LUW risks — reasoning lens | `references/lens-runtime.md` |
| `EFFIC` | Irrational / suboptimal code beyond PERF/CLEAN — reasoning lens | `references/lens-efficiency.md` |

Config rules:
- Rules requiring a config field (namespace, naming patterns, etc.) are skipped silently when that field is absent — do not report them as "not checked".
- `skip_categories` excludes those codes. `active_categories` runs only those codes and overrides `skip_categories`.
- `rule_suppressions` skips individual rule IDs across all objects.
- `suppress_severities` omits findings at those levels; CRITICAL is always included.
- A category or rule named explicitly in the user's request overrides config.

---

## Phase 2 — Detect Input Mode

Check modes in order — first match wins.

**Mode A — Paste:** A code block containing ABAP, CDS, or BDEF source is present in the conversation. Source is already available. Use the object name from the `CLASS`/`INTERFACE`/`DEFINE` statement as the report header, or `INLINE` if indeterminate.

**Mode B — Single ADT Object:** `$ARGUMENTS` is a single token that is not a transport number and not a package name. Invoke **`abap-vs-reader`** to read the source. If `abap-vs-reader` cannot resolve the source via virtual URI, ask the user to paste the source or confirm to skip — only after explicit confirmation, note `[SOURCE NOT FOUND]` and continue.

**Mode C — Transport / Package / Object Set:** `$ARGUMENTS` matches:
- Transport request number — `<3-char SID>K<6-digit>`, e.g. `DEVK900123`
- Comma-separated list of two or more object names
- Package name (identifiable by namespace prefix from config)

Invoke **`abap-vs-reader`** for each object sequentially. If `abap-vs-reader` cannot resolve the source via virtual URI for an object, ask the user: open the object in VS Code, paste the source, or skip explicitly. Only after explicit confirmation, note `[SOURCE NOT FOUND]`. Collect all sources before proceeding to Phase 3. Produce one consolidated report.

**No match:** Ask exactly one scoping question. See `references/review-scope-playbook.md`.

---

## Phase 2.5 — Pre-check Gate (automated, before manual analysis)

Resolve output mode (Phase 2.6) before running checks. Execute pre-checks once
per identified object against the same system/source revision as the manual
review. Pasted/unnamed or historical source without a matching runnable target
is not executed, not checked against an unrelated active object. Results go in
the Pre-check block and chat suffix, with concise sanitized failure diagnostics
and a safe result reference when available.

Read `references/pre-check.md` for the full procedure and config fields. Summary:

1. **Tool activation** — ensure the ATC and unit-test MCP tools are available. If not, both signals become `⚠️ not executed (tool unavailable)` and the review continues.
2. **ATC run** — read `atc_variant` from `configs/config.md`; call the ATC MCP tool (with or without `checkVariant`); count findings whose priority is not in `atc_ignore_priority` (default `[info]`). Use the ABAP name (`/DEMO/CL_X`), NOT the virtual-FS display name.
3. **Unit tests** — run only for object types listed in `unit_test_eligible_extensions` (typical: class, executable program, function-group function). Everything else — CDS, BDEF, service bindings, DDIC — is **skipped silently** (no line, no header suffix).
4. **Assemble** the `## Pre-check` block per `references/reporting-format.md` § *Pre-check block*.

Behaviour rules:

- Pre-check outcomes do **not** contribute to the CRITICAL / WARNING / INFO counters. They are a separate signal.
- Use the canonical combined header rule in reporting-format.md: failed checks
  block green, unavailable/incomplete evidence is yellow.
- Continue to Phase 3 regardless of pre-check outcome — pre-check does **not** gate manual analysis.
- ATC unavailable is visible, not silently skipped. Omit only checks proven
  inapplicable; do not hide failed/unavailable checks or coverage gaps.

---

## Phase 2.6 — Choose Output Mode

Skip if `configs/config.md` defines `output_mode: chat | file | both` — use that value and continue to Phase 3.

Otherwise ask exactly once before pre-check execution or output-file creation:

> **"How should I deliver the review?"**
> 1. **Chat only** — full report in conversation, no file written.
> 2. **File only** — full report to `docs/code-reviews/…`, short summary in chat.
> 3. **Both** — full report in chat and written to file.

Wait for the user's answer. Do not pre-select or recommend any option. Record the choice and use it in Phase 7.

---

## Phase 3 — Collect Evidence

Read `references/review-scope-playbook.md` before collecting.

### 3.a — Diff vs. full source

When reviewing a **transport request or a change set** (Mode C), the diff alone is insufficient. For every changed object:

1. **Read the full activated source** of the object — not only the diff hunks. Use `abap-vs-reader` (or `read_file` with a known virtual URI).
2. For global ABAP classes read **all sibling includes**:
   - `*.clas.definitions.abap` — local type pool, `DEFINITION` blocks
   - `*.clas.implementations.abap` — local `IMPLEMENTATION` blocks; for RAP behavior pools the entire handler logic lives here — the `*.clas.abap` wrapper is empty by convention
   - `*.clas.macros.abap` — when present
   - `*.clas.testclasses.abap` — when `TEST` is active
3. The diff provides the **scope of change**; the full source provides **context, existing patterns, and the pre-existing state** that the change relies on.

Reading only diff hunks without the full source is a **verification gap** — state which objects were read in full and which were not.

For **single-object or paste reviews** (Modes A and B), the full source is already available; step 1 above is satisfied by definition.

### 3.b — Dependency pull

For each changed artifact, identify **direct dependencies** affected by the change:

| Changed type | Dependencies to pull |
|---|---|
| CDS interface view | Projection views consuming it; BDEF / behavior pool that references it |
| BDEF | Behavior pool (all includes); DCLS roles for the CDS entities it governs; projection BDEF if present |
| Behavior pool class | BDEF it implements; any sibling handler classes for the same root BO |
| DDIC table | CDS views that select from it; BDEF mapping section |
| DCLS (access control) | The CDS entity it protects; roles it inherits from or that inherit from it |
| ABAP program / report | Any class it instantiates that changed in this TR |

Pull only the **direct** dependencies (one hop). Do not cascade further unless a finding requires it. If a dependency cannot be read, record a `verification gap`.

If an include is empty or absent, record it as such and continue. If it cannot be read, record a `verification gap`.

Do not expand into broad repository exploration — pull only what is needed to support a finding or explain a gap.

### 3.c — Dependency fetch procedure

When a dependency is required (referenced class, interface, BDEF, CDS, structure, data element, parent exception, secondary include, etc.):

1. If the virtual URI for the artifact is already known, call `read_file` on it directly.
2. Otherwise invoke **`abap-vs-reader`** with the artifact's display name or ADT path — it handles URI construction, index lookup, and sub-package resolution.
3. If the reader cannot resolve it, ask the user for a corrected name / namespace or confirmation the artifact is out of scope.
4. Only after exhausting steps 1–3, record a `verification gap` and continue. Never silently skip.

Reading only `*.clas.abap` for a class with non-empty includes is a `verification gap` — state which includes were read, which were skipped, and why.

---

## Phase 3.5 — Consistency Check

After collecting the full sources and direct dependencies, verify **cross-artifact consistency** before the architecture and rule passes. This phase surfaces mismatches that are invisible when each artifact is reviewed in isolation.

Check the following, in order:

### BDEF ↔ Behavior Pool

- Every entity declared in the BDEF (`define behavior for`) has a matching `lhc_<entity>` local handler class in the pool's `*.clas.implementations.abap`.
- Every operation declared in the BDEF (`create`, `update`, `delete`, action, determination, validation) has a matching `METHOD` in the handler class.
- Every field listed in a BDEF `mapping` section exists in the corresponding DDIC table (or draft table).
- `authorization master ( global )` claim ↔ `get_global_authorizations` method present and non-trivial in the handler.
- `authorization dependent by _<assoc>` ↔ no `get_global_authorizations` override needed for that entity.

### CDS view ↔ BDEF mapping

- Every key field in a CDS interface view that is also a key field in the BDEF has a `mapping` entry, or a `readonly : update` or `numbering : managed` qualifier.
- New fields added to a CDS view are reflected in the BDEF `mapping` section (and the DDIC table) within the same TR or a noted dependency.

### CDS view ↔ DCLS role

- Every `select on <entity>` in a DCLS role matches an existing activated CDS view (or the one being introduced in this TR).
- `inheriting conditions from entity <E>` — the referenced entity `<E>` exists and its own DCLS role defines the conditions it inherits.
- Auth objects referenced in `pfcg_auth(…)` clauses are consistent across all DCLS roles that protect the same root BO (e.g. same field names).

### CDS association key changes

- When the join key of an association changes (e.g. from `Oskey` to `SolDosKey`), check that:
  - the new key field is populated before the view is called (data migration, determination, or initial value);
  - the cardinality annotation (`[1]`, `[0..1]`, `[1..*]`) still holds after the key change;
  - any dependent projection views, metadata extensions, and search-help bindings reference the correct element name.

### DDIC table ↔ CDS view / BDEF

- New DDIC table fields appear in the corresponding interface CDS view's select list (or are deliberately omitted with a comment).
- The BDEF `mapping` section maps the new DDIC field to the CDS element name.
- Draft table (if the BO is draft-enabled) contains the new field.

### Projection view / metadata extension ↔ interface view

- All elements exposed in a projection view exist in the underlying interface view.
- Metadata extensions refer to elements that still exist after any rename or removal in the interface view or projection.

**Output of Phase 3.5:**

- Confirmed consistency issues → `confirmed finding` (typically CRITICAL or WARNING) under category `ARCH` / `RAP` / `CDS`.
- Suspected issues with incomplete evidence → `architectural suspicion`.
- Unverifiable items (dependency not readable) → `verification gap`.

Do NOT duplicate findings that will be raised by Phase 5 static rules — add only what this cross-artifact check uniquely reveals.

---

## Phase 4 — Architecture-First Analysis

Read `references/best-practices.md` before this phase.

Review each object as a solution. Determine:
- stated or implied purpose
- main control flow and data flow
- contracts between objects, layers, or RAP/CDS artifacts
- correctness risks, edge-case failures, error-handling gaps
- duplicate logic, dead branches, outdated or unused code when evidence supports it
- weaknesses in tests or missing regression protection

Classify results:
- `confirmed finding` — defect supported by source and context → findings table
- `architectural suspicion / review lead` — strong signal, not fully proven → only when `ARCH` active
- `verification gap` — conclusion depends on missing source or unavailable check

Do not hide assumptions inside findings — move them to verification gaps.

---

## Phase 5 — Rule-Backed Validation

Two sub-passes, in this order:

### 5.a — Static rule catalog

Apply active **static** categories in the order listed in the Phase 1 table (`ARCH`, `PERF`, `CLEAN`, `NAME`, `RAP`, `CDS`, `CCORE`, `TEST`, `TESTSUG`, `DOC`). Read a rule file only when its category is active. Report only rules with an actual violation — omit clean categories entirely. Do not let low-severity style issues outrank behavioural defects.

Catalog patterns and severities are review candidates, not proof of a defect.
Confirm the actual source/caller guarantees, platform and project contract,
and observable impact before assigning severity. A legacy statement, join,
extension point or naming pattern alone is not a behavioral blocker.

### 5.b — Review lenses (LOGIC / RUNTIME / EFFIC)

Apply the reasoning heuristics in `references/lens-logic.md`, `references/lens-runtime.md`, `references/lens-efficiency.md`. These lenses have **no rule IDs** — the agent must reason about the specific code and name the concrete defect / risk / waste in the finding text.

Rules for both sub-passes:

- Report only violations backed by evidence in the source. If you cannot name a plausible input for a LOGIC / RUNTIME finding, downgrade to WARNING or move to `## Architectural suspicions`.
- Do NOT let low-severity style issues outrank behavioural defects found in Phase 4 or in the lens pass.
- **Do not print the internal category code (`ARCH`, `RAP`, `LOGIC`, `RUNTIME`, `EFFIC`, …) in the report** — it stays inside the workflow to drive the analysis, per `## Categories — internal only`.
- Deduplicate against actual observed pre-check findings, not a guess about
  what ATC would raise. Preserve a source-confirmed blocker and its cause even
  when ATC also reports it; reference the observed result instead of duplicating.

### Contextual exclusions

The following patterns alone do not prove defects. Apply the contextual
exclusions in reporting-format.md; they never suppress independently proven
broken behavior or required pre-check failures:

1. **Empty behaviour pool referenced by a BDEF outside the current change set** — `references/rap-review.md`.
2. **Naming inconsistency among sibling local behaviour-handler classes** — `references/naming-convention.md`.

---

## Phase 5.5 — Deduplicate

Before rendering. Apply `references/reporting-format.md` § *Deduplication rules*:

1. Same location + same root cause → merge into one finding at the highest observed severity.
2. Same root cause, different locations → one finding, multiple entries joined by ` · ` in `Artifact` / `Location`.
3. A strictly resolved by fixing B → drop A.
4. Cross-severity duplicates (same defect, different rules) → keep the higher severity.
5. Never emit `Merged:` or `Deduplicated:` traces — dedup is internal.

---

## Phase 6 — Format Output

Read `references/reporting-format.md` for the full contract: header line, section order, glance table, card template, finding IDs, dedup rules, prohibited elements, Local Classes / Includes section, consolidated `_summary.md` structure, file-path conventions, and wording rules. That file is the single source of truth for report layout — do **not** invent additional sections or reorder the mandated ones.

---

## Phase 7 — Deliver the Report

### Mode `chat`
Print the complete report in the conversation. Do not create any file.

### Mode `file`
Write the complete report to file(s) per the path conventions in `references/reporting-format.md`. After writing, reply in chat with one block per reviewed object (and one aggregated block for transports / packages):

```
File: <filename>
Header: <🔴|🟡|🟢> · <N> CRITICAL · <N> WARNING · <N> INFO · ATC <✅|❌|⚠️> · tests <✅|❌|⚠️|➖>
```

Rules for the chat reply:

- **Never** print the words `GO`, `NO-GO`, `CONDITIONAL GO`.
- Use reporting-format.md's combined header rule for both file and chat.
- Counters are always three, always in order CRITICAL → WARNING → INFO, always shown (use `0` explicitly).
- **Pre-check suffix**: append ATC and eligible tests using reporting-format.md.
  Failed/timeout/unavailable states remain visible; ineligible tests are omitted.
- For transport / package reviews, add a final block for the aggregated `_summary.md` in the same shape; ATC / tests icons aggregate to the worst state across objects (`❌ > ⚠️ > ✅`).

If there are verification gaps, unresolved dependencies, or objects that could not be read, append a compact block after the header line(s):

```
Gaps: <object or include name> — <one-line reason>
```

One line per gap. Nothing else in chat.

### Mode `both`
Print the complete report in chat, then write to file(s) per the path conventions in `references/reporting-format.md`. Confirm the file path(s) at the end.

If a write fails, fall back to `chat` mode and report the error.
