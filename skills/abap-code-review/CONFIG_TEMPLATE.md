# abap-code-review — Config Template

## Required in `configs/config.md`

Fields may live in `configs/config.md` directly or in any file lazy-linked
from it via `→ Read configs/<file>.md for ...`.

- `primary_namespace` — ABAP namespace prefix for NAME-01 check (e.g. `/DEMO/`)
- `ddic_naming_rules` — Naming patterns for Domain, Data Element, Structure, Table Type, DB Table
- `cds_naming_rules` — Naming patterns for Interface View, Projection View, Base View, Draft table, TP view
- `bp_class_pattern` — Behavior Implementation Class naming pattern for NAME-04

## Recommended Fields

- `auth_check_class_pattern` — Class pattern for RAP-04 authorization delegation check
- `service_binding_suffix_rules` — Naming rules for Service Definition and Service Binding (NAME-07)
- `obsolete_package` — Package where obsolete objects should be assigned (DOC-05)

## Category Control

- `active_categories` — Run only the listed category codes; all others are skipped. Takes precedence over `skip_categories`.
  Example: `active_categories: [ARCH, PERF, RAP]`
- `skip_categories` — Skip the listed category codes entirely.
  Example: `skip_categories: [DOC, TESTSUG]`

Available category codes:

- `ARCH` — architectural suspicions, review leads, duplicate logic, dead or outdated code, risky assumptions
- `PERF` — performance and SQL checks
- `CLEAN` — Clean ABAP checks
- `NAME` — naming checks
- `RAP` — RAP correctness checks
- `CDS` — CDS architecture checks
- `CCORE` — Clean Core checks
- `TEST` — testability checks in the reviewed code
- `TESTSUG` — suggested additional tests section
- `DOC` — documentation checks

Notes:

- `ARCH` controls the optional `Architectural suspicions / review leads` section.
- `TESTSUG` controls the optional `Suggested tests` section.
- Confirmed defects can still appear in the findings table under any active category, including architecture-driven analysis.

## Rule Suppression

- `rule_suppressions` — Rule IDs to suppress across all objects.
  Example: `rule_suppressions: [DOC-03, NAME-05]`
  Use when a rule is systematically irrelevant for the project (e.g. `DOC-03` when KT docs are tracked externally).

- `suppress_severities` — Severity levels to omit from the report output. CRITICAL is always included.
  Example: `suppress_severities: [INFO, WARNING]`
  Use to focus the report on blockers only.

## Output Mode

- `output_mode` — Where to deliver the review output. Skips the Phase 2.5 question when set.
  Allowed values: `chat`, `file`, `both`.
  Example: `output_mode: file`
  - `chat` — print the full report in the conversation; no file is written.
  - `file` — write the full report to `docs/code-reviews/…` (one file per object plus `_summary.md` for multi-object reviews); reply in chat with a short summary only. Recommended for transports / packages / ≥ 5 objects.
  - `both` — print in chat **and** write to file (legacy default).
  When unset, the skill recommends a mode based on review size and asks the user to confirm.

## Lazy Loading

`config.md` is the required entry point. Use `→ Read configs/naming.md for ...` to link additional files.

## Global Behaviour

Rules that reference a config field are skipped silently when that field is absent — no "not checked" entry is written to the report.

`rule_suppressions` applies to rule IDs from the rule-backed validation pass. It does not disable architecture-driven findings; use `active_categories` or `skip_categories` for that.
