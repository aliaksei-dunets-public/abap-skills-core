# Pre-check Gate

Automated evidence before manual analysis, after scope/output mode resolution.
Record system, object, source revision and result ID. Keep concise sanitized
failure diagnostics and safe result references; do not dump full logs/secrets.

The pre-check does NOT contribute to the CRITICAL / WARNING / INFO counters. It is a separate signal, rendered in its own `## Pre-check` section and in the chat header suffix.

## Sub-steps (in order)

### 1. Tool activation

Ensure the MCP tool group containing `abap_atc_run`, `abap_atc_get_result`, and `run_unit_tests` is active. If the environment cannot activate them, treat both signals as `⚠️ not executed (tool unavailable)` and continue — do **not** abort the review.

### 2. ATC run

Applies to **every** reviewed object type — classes, programs, function groups, CDS, BDEF, service definitions/bindings, etc.

1. Read `atc_variant` from `configs/config.md`. If absent or empty, call `abap_atc_run` **without** `checkVariant`. If non-empty, pass it as `checkVariant`.
2. Poll at intervals of at least 10 seconds, bounded by both
   `atc_timeout_seconds` (default 300) and `atc_max_polls` (default 30).
   Stop at the first limit, cancellation, permanent error or changed target.
   A timeout/incomplete response is unknown, never clean. Retain the job ID;
   cancel only if supported and authorized, otherwise report it may still run.
   Never launch a duplicate job after an ambiguous start; inspect the known
   job/actual state first. Honor any shorter runtime/user limit.
3. Count findings whose priority is NOT in `atc_ignore_priority` (default: `[info]` — only `error` + `warning` contribute to the `❌` verdict).
4. Record counts, a concise sanitized diagnostic, and result ID/safe ADT link.
   Keep blockers visible without copying the entire tool report.

Object-name convention: pass the **ABAP name** with namespace slashes (e.g. `/DEMO/CL_HANDLER`), NOT the virtual-FS display name (e.g. `(DEMO)CL_HANDLER`). The latter typically triggers a null error from the MCP tool.

Map the outcome:

| Condition | Pre-check line | Header suffix |
|---|---|---|
| Tool group could not be activated / tool absent | `- ATC: ⚠️ not executed (tool unavailable)` | `· ATC ⚠️` |
| Errors + warnings = 0 | `- ATC: ✅ clean` | `· ATC ✅` |
| Errors + warnings > 0 | `- ATC: ❌ did not pass (<N> errors, <M> warnings) — <diagnostic; result ID/link>.` | `· ATC ❌` |
| Timeout, incomplete result or execution error | `- ATC: ⚠️ not verified — <reason; job ID if known>.` | `· ATC ⚠️` |

### 3. Unit tests

Applies **only** to object types listed in `unit_test_eligible_extensions` (typical: class, executable program, function-group function). Everything else — CDS, BDEF, service definitions/bindings, DDIC objects — is **skipped silently** (no line in `## Pre-check`, no `· tests …` suffix in the header).

1. Verify a safe test target and dependency isolation before calling the runner
   with the verified object URI. If isolation/side effects or matching source
   cannot be established, report not executed. LOCAL MODE/HARMLESS alone are
   not proof. Honor the tool/user execution timeout; a timed-out run is unknown
   and must not be restarted blindly.
2. Aggregate: number of failing tests, number of tests total.

Map the outcome (eligible objects only):

| Condition | Pre-check line | Header suffix |
|---|---|---|
| Tool unavailable | `- Unit tests: ⚠️ not executed (tool unavailable)` | `· tests ⚠️` |
| Confirmed no tests | `- Unit tests: ➖ no tests found.` | `· tests ➖` |
| Any observed test failure / test error | `- Unit tests: ❌ <N> failing — <sanitized diagnostic; result ID/link>.` | `· tests ❌` |
| Execution error, timeout or unknown isolation | `- Unit tests: ⚠️ not verified — <reason>.` | `· tests ⚠️` |
| All pass | `- Unit tests: ✅ <N>/<N> passing.` | `· tests ✅` |

### 4. Assemble the pre-check block

Collect the produced lines under a `## Pre-check` heading (see `reporting-format.md` § *Pre-check block*). If BOTH lines are skipped, omit the entire block.

## Configuration fields

All fields live in `configs/config.md` or a file lazy-loaded from it. See `CONFIG_TEMPLATE.md` for authoritative descriptions.

| Field | Default | Purpose |
|---|---|---|
| `atc_variant` | *(unset — uses system default variant)* | ATC check variant passed to the MCP call. |
| `atc_timeout_seconds` | `300` | Positive maximum ATC wait duration. |
| `atc_max_polls` | `30` | Positive maximum result polls; stop at first limit. |
| `atc_ignore_priority` | `[info]` | Priorities that do NOT contribute to the ❌ verdict. |
| `unit_test_eligible_extensions` | `[.clas.abap, .prog.abap, .fugr.func.abap]` | Object types on which unit tests run. All others are silently skipped. |

## Consolidated view (transports / multi-object)

For transport / package reviews, aggregate per `reporting-format.md` § *Pre-check block — Consolidated shape*. Rule of thumb: worst icon wins (`❌ > ⚠️ > ✅`), and the summary line explicitly lists how many objects failed / were skipped / passed.
