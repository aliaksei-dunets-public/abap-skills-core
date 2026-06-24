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

| Code | Purpose | Rule file |
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

**Mode B — Single ADT Object:** `$ARGUMENTS` is a single token that is not a transport number and not a package name. Invoke **`abap-vs-reader`** to read the source. If the reader exhausts its fallback chain, ask the user to paste the source or confirm to skip — only after explicit confirmation, note `[SOURCE NOT FOUND]` and continue.

**Mode C — Transport / Package / Object Set:** `$ARGUMENTS` matches:
- Transport request number — `<3-char SID>K<6-digit>`, e.g. `DEVK900123`
- Comma-separated list of two or more object names
- Package name (identifiable by namespace prefix from config)

Invoke **`abap-vs-reader`** for each object sequentially. When the reader exhausts its fallback chain for an object, ask the user: open the object in VS Code, paste the source, or skip explicitly. Only after explicit confirmation, note `[SOURCE NOT FOUND]`. Collect all sources before proceeding to Phase 3. Produce one consolidated report.

**No match:** Ask exactly one scoping question. See `references/review-scope-playbook.md`.

---

## Phase 2.5 — Choose Output Mode

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

Apply active categories in the order listed in the Phase 1 table. Read a rule file only when its category is active. Report only rules with an actual violation — omit clean categories entirely. Do not let low-severity style issues outrank behavioral defects.

---

## Phase 6 — Format Output

Read `references/reporting-format.md` for: severity scale, findings table template, Local Classes / Includes section, consolidated summary format, optional sections, output order, and file path conventions.

---

## Phase 7 — Deliver the Report

### Mode `chat`
Print the complete report in the conversation. Do not create any file.

### Mode `file`
Do not print the full report in chat. Write to file(s) per the path conventions in `references/reporting-format.md`. Reply with a short summary: objects reviewed, verdict tally, top 3 severity themes, file paths created.

### Mode `both`
Print the complete report in chat, then write to file(s) per the path conventions in `references/reporting-format.md`. Confirm the file path(s) at the end.

If a write fails, fall back to `chat` mode and report the error.
