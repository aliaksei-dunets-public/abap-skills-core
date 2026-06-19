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

Run an evidence-based ABAP solution review. Start with architecture, behavior, and related
context. Use rule files as a second validation pass. Produce a severity-graded findings table,
optional architecture leads, optional suggested tests, and a release gate verdict per object.

This skill is assessment-only. It does not implement fixes.

---

## Phase 1 — Load Config and Resolve Categories

### Config

Read `configs/config.md` if it exists. If it references additional files (e.g. `→ Read configs/naming.md for ...`), read those too.

Resolve active categories before reviewing. Default to all categories when no category filter exists.

| Category | Purpose | Reference |
|---|---|---|
| `ARCH` | Architecture leads, inconsistency signals, duplicate logic, dead or outdated code, risky assumptions | `references/best-practices.md` |
| `PERF` | Performance and SQL risks | `references/rules-performance.md` |
| `CLEAN` | Clean ABAP issues | `references/rules-clean-abap.md` |
| `NAME` | Naming rules | `references/naming-convention.md` |
| `RAP` | RAP correctness | `references/rap-review.md` |
| `CDS` | CDS architecture rules | `references/rules-cds.md` |
| `CCORE` | Clean Core risks | `references/clean-core.md` |
| `TEST` | Testability issues in the code | `references/rules-testability.md` |
| `TESTSUG` | Suggested additional tests | `references/best-practices.md` |
| `DOC` | Documentation issues | `references/rules-documentation.md` |

Apply these config rules:

- Any rule that requires a config field (namespace prefix, naming patterns, class patterns, etc.) is **skipped silently** when `configs/config.md` is absent or when that specific field is not defined. Do not report those rules as "not checked" — simply omit them.
- If `configs/config.md` defines `skip_categories`, exclude those category codes entirely (e.g. `skip_categories: [DOC, TESTSUG]`).
- If `configs/config.md` defines `active_categories`, run only those category codes and skip the rest (e.g. `active_categories: [ARCH, PERF, RAP]`). `active_categories` takes precedence over `skip_categories`.
- If `configs/config.md` defines `rule_suppressions`, skip those individual rule IDs across all objects in the rule-backed validation pass.
- If `configs/config.md` defines `suppress_severities`, omit all findings at those severity levels from the output. CRITICAL findings are always included regardless of this setting. Example: `suppress_severities: [INFO, WARNING]` produces a CRITICAL-only report.

A category named explicitly in the user's request overrides both config and defaults. A rule named explicitly in the user's request overrides rule suppressions.

## Phase 2 — Detect Input Mode and Review Reach

Examine the conversation to determine which mode applies. Check modes in the order listed — the first match wins.

**Mode A — Paste:** A code block containing ABAP, CDS, or BDEF source is present anywhere in the conversation (current or prior turns). Source is already available — proceed directly to Phase 3. Use the object name from the `CLASS`/`INTERFACE`/`DEFINE` statement as the report header, or `INLINE` if it cannot be determined.

**Mode B — Single ADT Object:** `$ARGUMENTS` contains a single token that is **not** a transport request number (see format below) and **not** a package name. Collect the object's source before continuing. If no source is obtained, note `[SOURCE NOT FOUND]` in the report and continue.

**Mode C — Transport / Package / Object Set:** `$ARGUMENTS` matches one of:
- A transport request number — format `<3-char SID>K<6-digit number>`, e.g. `DEVK900123`
- A comma-separated list of two or more object names
- A single package name (identifiable by the project namespace prefix from config, e.g. `/DEMO/MY_PACKAGE`)

For a transport or object list: collect the source for each object sequentially. For a package: do the same for each reviewable object in the package. Collect all sources before proceeding to Phase 2. For any object not found, note `[SOURCE NOT FOUND]` in its section. Produce one consolidated report.

**No match:** If none of the above applies — no paste in conversation, no recognisable `$ARGUMENTS` — ask exactly one scoping question before proceeding. See `references/review-scope-playbook.md` for guidance on scoping decisions and evidence standards.

---

Before judging any object, read `references/review-scope-playbook.md` and collect the minimum related context needed to understand behavior:

- related includes or implementation parts
- local tests or test includes when present
- nearby dependencies, callers, contracts, CDS/BDEF/BIMP artifacts, or interfaces when they are required to explain purpose, behavior, impact, or released API status

**Mandatory for global ABAP classes — local-class includes:** When reviewing a global class (`*.clas.abap`) you **must** also read its sibling includes before producing the report:

- `*.clas.definitions.abap` — local type pool, local class `DEFINITION` blocks (`lcl_*`, `lcx_*`, RAP `lhc_*` / `lsc_*` declarations).
- `*.clas.implementations.abap` — local class `IMPLEMENTATION` blocks. **For RAP behavior pools (`FOR BEHAVIOR OF …`) the entire handler logic lives here**; the wrapper `*.clas.abap` is empty by convention. Treating the wrapper as "the class" produces incorrect verdicts.
- `*.clas.macros.abap` — local macro definitions when present.

If an include is empty or absent, record it as such and continue. If an include cannot be read (virtual filesystem, ADT cache miss, missing authorization), record a verification gap rather than skipping silently.

Do not expand into broad repository exploration. Pull only the artifacts needed to support a finding or to explain a verification gap.

## Phase 3 — Collect Evidence

For each object, collect actual evidence before reporting findings:

- active source
- **for global classes: all four sibling includes** (`*.clas.definitions.abap`, `*.clas.implementations.abap`, `*.clas.macros.abap`, plus `*.clas.testclasses.abap` when `TEST` is active)
- changed logic paths when the review targets a transport, task, or change set
- related tests when changed logic should be covered
- syntax, ABAP Unit, ATC, references, or dependency evidence when available

Use the evidence available in the current environment. Do not prescribe a retrieval chain.

If a required artifact cannot be read or a check cannot be executed, record a `verification gap` instead of guessing. **Reading only `*.clas.abap` for a class with non-empty includes is a verification gap, not a clean review** — explicitly state which includes were read, which were skipped, and why.

## Phase 4 — Architecture-First Analysis

Read `references/best-practices.md` before this phase.

Review each object as a solution, not just as a rule checklist. Determine:

- stated or implied purpose
- main control flow and data flow
- contracts between objects, layers, or RAP/CDS artifacts
- likely correctness risks, edge-case failures, and error-handling gaps
- duplicate logic, dead branches, outdated code, or unused code when evidence supports it
- weaknesses in tests or missing regression protection

Classify results with evidence discipline:

- `confirmed finding` — the defect or risk is supported by source and context; report it in the findings table
- `architectural suspicion / review lead` — the signal is strong but not fully proven; report it only when `ARCH` is active
- `verification gap` — the conclusion depends on missing source, missing tests, or an unavailable check

Do not hide assumptions inside findings. Move them to assumptions or verification gaps.

## Phase 5 — Rule-Backed Validation

For every source collected, apply the active rule categories below in order. Read a rule file only when its category is active. Only report rules where a violation is actually present — omit clean categories entirely.

| # | Category | Rule file | Code |
|---|----------|-----------|------|
| 1 | Performance | `references/rules-performance.md` | PERF |
| 2 | Clean ABAP | `references/rules-clean-abap.md` | CLEAN |
| 3 | Naming | `references/naming-convention.md` | NAME |
| 4 | RAP Correctness | `references/rap-review.md` | RAP |
| 5 | CDS Architecture | `references/rules-cds.md` | CDS |
| 6 | Clean Core | `references/clean-core.md` | CCORE |
| 7 | Testability | `references/rules-testability.md` | TEST |
| 8 | Documentation | `references/rules-documentation.md` | DOC |

Use rule files to validate and sharpen the architecture-first review. Do not let low-severity style issues outrank behavioral defects.

---

## Phase 6 — Format Output

Read `references/reporting-format.md` for the exact output structure, severity scale, findings table template, optional sections, release gate verdict format, and consolidated summary format.

---

## Phase 7 — Save Report

After producing the full output in chat, ask the user: **"Save the report to `docs/code-reviews/`?"**

If yes:
1. Determine the current datetime in `YYYY-MM-DD_HH-MM` format.
2. Derive a descriptive filename:
   - Single object: kebab-case of the object name (e.g. `bp-i-con-ip` from `(DEMO)BP_I_CON_IP`)
   - Multiple objects / transport: TR number or user-supplied label from `$ARGUMENTS` (e.g. `transport-XYZK9A05GC`)
   - Pasted code / no name: `inline-review`
3. Create `docs/code-reviews/` if it does not exist.
4. Write the complete report (identical to the chat output) to:
   `docs/code-reviews/<YYYY-MM-DD_HH-MM>_<descriptive-name>.md`
5. Confirm: `Report saved: docs/code-reviews/2026-05-13_14-30_bp-i-con-ip.md`
