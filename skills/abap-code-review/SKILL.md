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

Execute this phase **once per reviewed object** immediately after the input mode is resolved. Results go into a dedicated `## Pre-check` block at the top of each per-object report and into the chat header line suffix (see Phase 7). Details are **omitted by design** — this gate signals *whether* the reviewer must open ATC / ADT, not *what* it found.

Read `references/pre-check.md` for the full procedure and config fields. Summary:

1. **Tool activation** — ensure the ATC and unit-test MCP tools are available. If not, both signals become `⚠️ not executed (tool unavailable)` and the review continues.
2. **ATC run** — read `atc_variant` from `configs/config.md`; call the ATC MCP tool (with or without `checkVariant`); count findings whose priority is not in `atc_ignore_priority` (default `[info]`). Use the ABAP name (`/DEMO/CL_X`), NOT the virtual-FS display name.
3. **Unit tests** — run only for object types listed in `unit_test_eligible_extensions` (typical: class, executable program, function-group function). Everything else — CDS, BDEF, service bindings, DDIC — is **skipped silently** (no line, no header suffix).
4. **Assemble** the `## Pre-check` block per `references/reporting-format.md` § *Pre-check block*.

Behaviour rules:

- Pre-check outcomes do **not** contribute to the CRITICAL / WARNING / INFO counters. They are a separate signal.
- The header icon rule (`🔴` if any CRITICAL survives Phase 5.5, else `🟢`) is unchanged.
- Continue to Phase 3 regardless of pre-check outcome — pre-check does **not** gate manual analysis.
- If BOTH signals were silently skipped (e.g. a DDIC artefact for which ATC is also unavailable), omit the entire `## Pre-check` block.

---

## Phase 2.6 — Choose Output Mode

Skip if `configs/config.md` defines `output_mode: chat | file | both` — use that value and continue to Phase 3.

Otherwise ask exactly once before collecting any evidence:

> **"How should I deliver the review?"**
> 1. **Chat only** — full report in conversation, no file written.
> 2. **File only** — full report to `docs/code-reviews/…`, short summary in chat.
> 3. **Both** — full report in chat and written to file.

Wait for the user's answer. Do not pre-select or recommend any option. Record the choice and use it in Phase 7.

---

## Phase 3 — Collect Evidence

Read `references/review-scope-playbook.md` before collecting.

For each object collect:
- active source (via `abap-vs-reader`)
- **global ABAP classes — all sibling includes:** once the main URI is known, read siblings directly with `read_file` by substituting the filename suffix:
  - `*.clas.definitions.abap` — local type pool, `DEFINITION` blocks
  - `*.clas.implementations.abap` — local `IMPLEMENTATION` blocks; for RAP behavior pools the entire handler logic lives here — the `*.clas.abap` wrapper is empty by convention
  - `*.clas.macros.abap` — when present
  - `*.clas.testclasses.abap` — when `TEST` is active
- changed logic paths when reviewing a transport or change set
- related tests when changed logic should be covered

If an include is empty or absent, record it as such and continue. If it cannot be read, record a `verification gap`.

Do not expand into broad repository exploration — pull only what is needed to support a finding or explain a gap.

### Fetching dependencies

When a dependency is required (referenced class, interface, BDEF, CDS, structure, data element, parent exception, secondary include, etc.):

1. If the virtual URI for the artifact is already known, call `read_file` on it directly.
2. Otherwise invoke **`abap-vs-reader`** with the artifact's display name or ADT path — it handles URI construction, index lookup, and sub-package resolution.
3. If the reader cannot resolve it, ask the user for a corrected name / namespace or confirmation the artifact is out of scope.
4. Only after exhausting steps 1–3, record a `verification gap` and continue. Never silently skip.

Reading only `*.clas.abap` for a class with non-empty includes is a `verification gap` — state which includes were read, which were skipped, and why.

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

### 5.b — Review lenses (LOGIC / RUNTIME / EFFIC)

Apply the reasoning heuristics in `references/lens-logic.md`, `references/lens-runtime.md`, `references/lens-efficiency.md`. These lenses have **no rule IDs** — the agent must reason about the specific code and name the concrete defect / risk / waste in the finding text.

Rules for both sub-passes:

- Report only violations backed by evidence in the source. If you cannot name a plausible input for a LOGIC / RUNTIME finding, downgrade to WARNING or move to `## Architectural suspicions`.
- Do NOT let low-severity style issues outrank behavioural defects found in Phase 4 or in the lens pass.
- **Do not print the internal category code (`ARCH`, `RAP`, `LOGIC`, `RUNTIME`, `EFFIC`, …) in the report** — it stays inside the workflow to drive the analysis, per `## Categories — internal only`.
- Do not duplicate what the pre-check gate already surfaced. If ATC would raise it, describe it as a lens finding only when you have added value beyond the ATC message (e.g. named the specific input, described a runtime consequence).

### Excluded checks — never emit

Even if the underlying rule fires, do **not** report the following patterns. They are false-positive-prone and are handled outside the review loop. Same list is documented in `references/reporting-format.md` § *Excluded from review output* and in the two rule files:

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
Header: <🔴|🟢> · <N> CRITICAL · <N> WARNING · <N> INFO · ATC <✅|❌|⚠️> · tests <✅|❌|⚠️>
```

Rules for the chat reply:

- **Never** print the words `GO`, `NO-GO`, `CONDITIONAL GO`.
- Icon rule: 🔴 if any CRITICAL, else 🟢. No 🟡 at the chat level.
- Counters are always three, always in order CRITICAL → WARNING → INFO, always shown (use `0` explicitly).
- **Pre-check suffix**: append `· ATC <icon>` after the counters using the icon set from Phase 2.5. Append `· tests <icon>` **only** when the object type is eligible for unit tests (see `unit_test_eligible_extensions`). Omit the `tests` segment entirely for CDS, BDEF, service definitions/bindings, and DDIC objects. Icons: `✅` clean · `❌` failed · `⚠️` not executed (tool unavailable) · `➖` no tests found (tests only).
- For transport / package reviews, add a final block for the aggregated `_summary.md` in the same shape; ATC / tests icons aggregate to the worst state across objects (`❌ > ⚠️ > ✅`).

If there are verification gaps, unresolved dependencies, or objects that could not be read, append a compact block after the header line(s):

```
Gaps: <object or include name> — <one-line reason>
```

One line per gap. Nothing else in chat.

### Mode `both`
Print the complete report in chat, then write to file(s) per the path conventions in `references/reporting-format.md`. Confirm the file path(s) at the end.

If a write fails, fall back to `chat` mode and report the error.
