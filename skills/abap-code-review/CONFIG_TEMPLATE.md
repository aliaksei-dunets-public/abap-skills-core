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

## Pre-check Gate

- `atc_variant` — ATC check variant. When absent or empty, omit `checkVariant` from the MCP call so SAP uses the system default.
  Example: `atc_variant: ZSECURITY_ATC_DEFAULT`
- `atc_ignore_priority` — ATC priorities that do not contribute to the failed pre-check status.
  Default: `atc_ignore_priority: [info]`
- `unit_test_eligible_extensions` — Object extensions for which the unit-test pre-check runs. Other object types are skipped silently.
  Default: `unit_test_eligible_extensions: [.clas.abap, .prog.abap, .fugr.func.abap]`
- `header_suffix` — Optional project-specific icons for ATC and unit-test states. When absent, use the icons defined in `references/reporting-format.md`.

See `references/pre-check.md` for execution and aggregation rules.

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
- `LOGIC` — hidden logical errors found through control-flow reasoning
- `RUNTIME` — realistic short-dump, lock, cursor, and LUW risks
- `EFFIC` — irrational or suboptimal code beyond static PERF/CLEAN rules

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

- `output_mode` — Where to deliver the review output. Skips the Phase 2.6 question when set.
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
