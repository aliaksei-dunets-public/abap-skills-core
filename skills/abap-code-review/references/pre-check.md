# Pre-check Gate

Automated evidence collected **before** manual analysis. Purpose: signal *whether* the reviewer must open ATC / ADT for details — the details themselves are **omitted by design** to keep the report focused on evidence the AI reviewer can add value to.

The pre-check does NOT contribute to the CRITICAL / WARNING / INFO counters. It is a separate signal, rendered in its own `## Pre-check` section and in the chat header suffix.

## Sub-steps (in order)

### 1. Tool activation

Ensure the MCP tool group containing `abap_atc_run`, `abap_atc_get_result`, and `run_unit_tests` is active. If the environment cannot activate them, treat both signals as `⚠️ not executed (tool unavailable)` and continue — do **not** abort the review.

### 2. ATC run

Applies to **every** reviewed object type — classes, programs, function groups, CDS, BDEF, service definitions/bindings, etc.

1. Read `atc_variant` from `configs/config.md`. If absent or empty, call `abap_atc_run` **without** `checkVariant`. If non-empty, pass it as `checkVariant`.
2. Poll the result endpoint until completion.
3. Count findings whose priority is NOT in `atc_ignore_priority` (default: `[info]` — only `error` + `warning` contribute to the `❌` verdict).
4. Do **not** record the specific findings, messages, or locations. The reviewer must open ATC in ADT for details.

Object-name convention: pass the **ABAP name** with namespace slashes (e.g. `/DEMO/CL_HANDLER`), NOT the virtual-FS display name (e.g. `(DEMO)CL_HANDLER`). The latter typically triggers a null error from the MCP tool.

Map the outcome:

| Condition | Pre-check line | Header suffix |
|---|---|---|
| Tool group could not be activated / tool absent | `- ATC: ⚠️ not executed (tool unavailable)` | `· ATC ⚠️` |
| Errors + warnings = 0 | `- ATC: ✅ clean` | `· ATC ✅` |
| Errors + warnings > 0 | `- ATC: ❌ did not pass (<N> errors, <M> warnings) — details omitted; run ATC in ADT.` | `· ATC ❌` |

### 3. Unit tests

Applies **only** to object types listed in `unit_test_eligible_extensions` (typical: class, executable program, function-group function). Everything else — CDS, BDEF, service definitions/bindings, DDIC objects — is **skipped silently** (no line in `## Pre-check`, no `· tests …` suffix in the header).

1. Call the unit-test runner MCP tool with the object URI.
2. Aggregate: number of failing tests, number of tests total.

Map the outcome (eligible objects only):

| Condition | Pre-check line | Header suffix |
|---|---|---|
| Tool unavailable | `- Unit tests: ⚠️ not executed (tool unavailable)` | `· tests ⚠️` |
| No test class / no `FOR TESTING` methods found | `- Unit tests: ➖ no tests found.` | (no suffix) |
| Any failure / error | `- Unit tests: ❌ <N> failing — details omitted.` | `· tests ❌` |
| All pass | `- Unit tests: ✅ <N>/<N> passing.` | `· tests ✅` |

### 4. Assemble the pre-check block

Collect the produced lines under a `## Pre-check` heading (see `reporting-format.md` § *Pre-check block*). If BOTH lines are skipped, omit the entire block.

## Configuration fields

All fields live in `configs/config.md` or a file lazy-loaded from it. See `CONFIG_TEMPLATE.md` for authoritative descriptions.

| Field | Default | Purpose |
|---|---|---|
| `atc_variant` | *(unset — uses system default variant)* | ATC check variant passed to the MCP call. |
| `atc_ignore_priority` | `[info]` | Priorities that do NOT contribute to the ❌ verdict. |
| `unit_test_eligible_extensions` | `[.clas.abap, .prog.abap, .fugr.func.abap]` | Object types on which unit tests run. All others are silently skipped. |

## Consolidated view (transports / multi-object)

For transport / package reviews, aggregate per `reporting-format.md` § *Pre-check block — Consolidated shape*. Rule of thumb: worst icon wins (`❌ > ⚠️ > ✅`), and the summary line explicitly lists how many objects failed / were skipped / passed.
