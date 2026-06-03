---
name: abap-code-review
description: >
  Use when reviewing ABAP objects, packages, transport requests, or transport tasks
  for defects, contract risks, Clean Core issues, RAP issues, or naming problems
  before release or handoff. Trigger on: "review this ABAP", "check this class/CDS/behavior
  definition", "code review for transport", pasted ABAP/CDS source code, or any mention of
  an object that needs review.
---

# ABAP Code Review

Run a structured expert ABAP code review covering performance, Clean ABAP, naming conventions,
RAP correctness, CDS architecture, Clean Core, testability, and documentation. Produces a
severity-graded findings table and a release gate verdict per object.

This skill is assessment-only. It does not implement fixes.

---

## Phase 1 — Load Config and Detect Input Mode

### Config

Read `configs/config.md` if it exists. If it references additional files (e.g. `→ Read configs/naming.md for ...`), read those too.

**Global config rules — apply to every rule in every category:**

- Any rule that requires a config field (namespace prefix, naming patterns, class patterns, etc.) is **skipped silently** when `configs/config.md` is absent or when that specific field is not defined. Do not report those rules as "not checked" — simply omit them.
- If `configs/config.md` defines `skip_categories`, exclude those category codes entirely (e.g. `skip_categories: [DOC, TEST]`).
- If `configs/config.md` defines `active_categories`, run only those categories and skip the rest (e.g. `active_categories: [PERF, CLEAN, RAP]`). `active_categories` takes precedence over `skip_categories`.
- If `configs/config.md` defines `rule_suppressions`, skip those individual rule IDs across all objects.

A category or rule named explicitly in the user's request overrides both config and defaults — always honour an explicit instruction to include or exclude a specific check.

### Input Mode

Examine the conversation to determine which mode applies. Check modes in the order listed — the first match wins.

**Mode A — Paste:** A code block containing ABAP, CDS, or BDEF source is present anywhere in the conversation (current or prior turns). Source is already available — proceed directly to Phase 3. Use the object name from the `CLASS`/`INTERFACE`/`DEFINE` statement as the report header, or `INLINE` if it cannot be determined.

**Mode B — Single ADT Object:** `$ARGUMENTS` contains a single token that is **not** a transport request number (see format below) and **not** a package name. Read `references/source-reader.md` and follow the detection chain to fetch the source. If no source is obtained, note `[SOURCE NOT FOUND]` in the report and continue.

**Mode C — Transport / Package / Object Set:** `$ARGUMENTS` matches one of:
- A transport request number — format `<3-char SID>K<6-digit number>`, e.g. `DEVK900123`
- A comma-separated list of two or more object names
- A single package name (identifiable by the project namespace prefix from config, e.g. `/DEMO/MY_PACKAGE`)

For a transport or object list: read `references/source-reader.md` and follow the detection chain for each object sequentially. For a package: do the same for each reviewable object in the package. Collect all sources before proceeding to Phase 2. For any object not found, note `[SOURCE NOT FOUND]` in its section. Produce one consolidated report.

**No match:** If none of the above applies — no paste in conversation, no recognisable `$ARGUMENTS` — ask exactly one scoping question before proceeding. See `references/review-scope-playbook.md` for guidance on scoping decisions and evidence standards.

---

## Phase 2 — Review Each Object

For every source collected, apply the active categories below in order. Read the corresponding reference file for the full rule table before checking each category. Only report rules where a violation is actually present — omit clean categories entirely.

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

For prioritization heuristics and review rationale, see `references/best-practices.md`.

---

## Phase 3 — Format Output

Read `references/reporting-format.md` for the exact output structure, severity scale, finding table template, release gate verdict format, and consolidated summary format (transport, package, or multi-object reviews).

---

## Phase 4 — Save Report

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
