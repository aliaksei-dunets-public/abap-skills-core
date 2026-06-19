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

**Mode A — Paste:** A code block containing ABAP, CDS, or BDEF source is present anywhere in the conversation (current or prior turns). Source is already available — no retrieval needed. Use the object name from the `CLASS`/`INTERFACE`/`DEFINE` statement as the report header, or `INLINE` if it cannot be determined.

**Mode B — Single ADT Object:** `$ARGUMENTS` contains a single token that is **not** a transport request number (see format below) and **not** a package name. Collect the object's source before continuing. If no source is obtained, note `[SOURCE NOT FOUND]` in the report and continue.

**Mode C — Transport / Package / Object Set:** `$ARGUMENTS` matches one of:
- A transport request number — format `<3-char SID>K<6-digit number>`, e.g. `DEVK900123`
- A comma-separated list of two or more object names
- A single package name (identifiable by the project namespace prefix from config, e.g. `/DEMO/MY_PACKAGE`)

For a transport or object list: collect the source for each object sequentially. For a package: do the same for each reviewable object in the package. Collect all sources before proceeding to Phase 2. For any object not found, note `[SOURCE NOT FOUND]` in its section. Produce one consolidated report.

**No match:** If none of the above applies — no paste in conversation, no recognisable `$ARGUMENTS` — ask exactly one scoping question before proceeding. See `references/review-scope-playbook.md` for guidance on scoping decisions and evidence standards.

**After resolving the input mode, always continue to Phase 2.5 before collecting any evidence.**

## Phase 2.5 — Choose Output Mode

**This phase is mandatory and must not be skipped, regardless of input mode.** The only exception: if `configs/config.md` defines `output_mode` with a value of `chat`, `file`, or `both` — in that case use the configured value silently and continue to Phase 3.

Before collecting evidence, ask the user how the review output should be delivered. Ask exactly one question with three options:

> **"How should I deliver the review?"**
>
> 1. **Chat only** — print the full report in the conversation; no file is written.
> 2. **File only** — write the full report to `docs/code-reviews/…` and reply with a short summary (objects reviewed, verdict tally, file paths). Use this for large reviews (transports, packages, ≥5 objects) to avoid flooding the chat.
> 3. **Both** — print in chat **and** write to file. This is the legacy default.

Apply these defaults to pick the recommended option but always honor the user's choice:

- Mode A (Paste) or single object — recommend **Chat only**.
- Mode B (Single ADT object) — recommend **Both**.
- Mode C (Transport / Package / Object Set) with ≥ 5 objects — recommend **File only**.
- Mode C with < 5 objects — recommend **Both**.

If `configs/config.md` defines `output_mode: chat | file | both`, skip the question and use the configured value. The user can still override the configured value in their request ("output to chat", "save to file only").

Record the chosen mode and use it consistently in Phase 6 and Phase 7. **Never** silently change the output destination after the user has chosen.

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

### Fetching dependencies — strict order

When the analysis requires a dependency that is not yet in scope (a referenced class, interface, BDEF, CDS, structure, data element, parent exception, secondary include, etc.), follow this order strictly:

1. **Try standard read tools first** (`read_file` on a virtual ADT URI, `grep_search`, `semantic_search`).
2. **If the artifact cannot be located or read** — invoke the **`abap-vs-reader`** skill with the artifact's display name or ADT path. The reader owns URI construction, sub-package chain resolution, the index cache, and its own ENOENT fallback (which already includes asking the user to open the object in VS Code so the ADT cache populates). Do not duplicate that logic here — always delegate.
3. **If `abap-vs-reader` reports it cannot resolve the artifact** (its fallback chain has been exhausted), **then** ask the user for the missing information — either a corrected name / namespace, a paste of the source, or confirmation that the artifact is intentionally out of scope.
4. **Only after exhausting steps 1–3** record a `verification gap` and continue with the rest of the review. Never silently skip a dependency.

Do **not** ask the user for an artifact before trying steps 1 and 2 — the reader's existing fallback already handles the common "object not yet in ADT cache" case.

Use the evidence available in the current environment. Do not prescribe a retrieval chain beyond what is described above.

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

## Phase 7 — Deliver the Report

Deliver the report according to the **output mode chosen in Phase 2.5**:

### Mode `chat`

Print the complete report in the conversation. Do **not** ask about saving and do **not** create any file. End the turn.

### Mode `file`

Do not print the full report in chat. Instead:

1. Determine the current datetime in `YYYY-MM-DD_HH-MM` format.
2. Derive the descriptive filename / folder layout:
   - **Single object** — file `docs/code-reviews/<YYYY-MM-DD_HH-MM>_<kebab-object-name>.md`.
   - **Transport / package / multi-object review** — a dedicated folder `docs/code-reviews/<TR-number-or-label>/` containing one file per reviewed object (kebab-case object name) plus `_summary.md` with the consolidated table and overall verdict. Use this layout whenever the review covers more than one object so each object's report stays focused and individually addressable.
   - **Pasted code / no name** — `docs/code-reviews/<YYYY-MM-DD_HH-MM>_inline-review.md`.
3. Create the target folder if it does not exist.
4. Write the complete report to file(s).
5. Reply in chat with a short summary only:
   - objects reviewed (count + names)
   - verdict tally (🟢 / 🟡 / 🔴 counts)
   - top 3 highest-severity themes (one line each)
   - the file paths created

### Mode `both`

Print the complete report in chat first, then write the same content to file using the layout described under Mode `file`. Confirm the file path(s) at the end.

---

### Notes

- The report content is identical across modes — only the delivery channel differs.
- For multi-object reviews, the per-object file layout (one file per object + `_summary.md`) is preferred even in `chat` mode if the user later asks to save: keep the structure consistent.
- If a write fails, fall back to `chat` mode and report the error so the user does not lose the analysis.
