# Reporting Format

Canonical behavioural contract for ABAP code-review reports produced by this skill. The visual example lives in the workspace overlay (per project). This file governs **what** must appear and **what must never** appear.

Two output surfaces are covered:

- **Per-object report** — one Markdown file per reviewed ABAP object (or a single file for a paste/single-object review).
- **Consolidated summary** — `_summary.md` for transports / packages / multi-object reviews.

---

## Severity scale

Exactly three severity levels. No fourth level, no numeric scores, no priority letters.

| Severity | Icon | Meaning | Release impact |
|---|---|---|---|
| CRITICAL | 🔴 | Likely defect, regression, data-integrity issue, transaction risk, or contract break. | Blocker. |
| WARNING | 🟡 | Meaningful quality, compliance, maintainability, or Clean Core risk. | Reviewer discretion. |
| INFO | 🟢 | Small clarity or convention issue with limited delivery risk. | No gate impact. |

## Header line

Every per-object report and every `_summary.md` starts with a one-line blockquote header:

```
> {{VERDICT_ICON}} · {{N}} CRITICAL · {{N}} WARNING · {{N}} INFO · TR `{{TR_NUMBER}}`
```

Rules:

- Icon: `🔴` if any CRITICAL, else `🟢`. **Never** print the words `GO`, `NO-GO`, `CONDITIONAL GO`.
- Counters: always three, always in order CRITICAL → WARNING → INFO. Show `0` explicitly.
- TR block optional — omit for single-object paste reviews without a transport context. When present, wrap the TR number in backticks.
- No standalone `## Verdict` section anywhere in the report.
- The **file header** does not include ATC / tests status. Those signals belong to the `## Pre-check` block and the **chat header suffix** below.

### Chat header suffix

For `file` and `both` modes, append pre-check status after the counters:

```
Header: <🔴|🟢> · <N> CRITICAL · <N> WARNING · <N> INFO · ATC <✅|❌|⚠️> · tests <✅|❌|⚠️|➖>
```

- Always append `· ATC <icon>` after the counters.
- Append `· tests <icon>` only when the object type is eligible for unit tests. Omit it for CDS, BDEF, service definitions/bindings, and DDIC objects.
- Icons: `✅` clean, `❌` failed, `⚠️` not executed because the tool was unavailable, `➖` no tests found (tests only).
- For a consolidated transport / package summary, aggregate each signal to the worst observed state: `❌` > `⚠️` > `✅`. Use `➖` for tests only when no eligible object has tests.

## Pre-check block

Place this section immediately after the file header and before `## What changed`:

```markdown
## Pre-check

- ATC: <status line>
- Unit tests: <status line>
```

Allowed status lines:

| Signal | Statuses |
|---|---|
| ATC | `✅ clean` · `❌ did not pass (<N> errors, <M> warnings) — details omitted; run ATC in ADT.` · `⚠️ not executed (tool unavailable)` |
| Unit tests | `✅ <N>/<N> passing.` · `❌ <N> failing — details omitted.` · `➖ no tests found.` · `⚠️ not executed (tool unavailable)` |

Omission and counting rules:

- For an object type ineligible for unit tests, omit the `Unit tests:` line entirely.
- If both signals were silently skipped, omit the entire `## Pre-check` block.
- Priorities listed in `atc_ignore_priority` do not count toward the failed ATC status.
- Pre-check outcomes do not contribute to CRITICAL / WARNING / INFO counters.

### Consolidated pre-check

For transport / package / multi-object summaries:

- `ATC: ❌ <X>/<Y> objects failed — details omitted; run ATC in ADT.` when any object failed.
- `ATC: ✅ all <Y> objects clean.` when ATC ran successfully for every object and none failed.
- `ATC: ⚠️ not executed on <Z> objects (tool unavailable).` when no failure exists but ATC was unavailable for at least one object.
- For mixed states, include a compact breakdown and use the worst icon, for example: `ATC: ❌ 3/12 failed · ⚠️ 2 not executed · ✅ 7 clean — details omitted; run ATC in ADT.`
- The unit-test denominator excludes ineligible object types. If no object is eligible, write `Unit tests: ➖ not applicable (no eligible object types).`

## Per-object report structure

Sections in this exact order:

1. `# {{OBJECT_NAME}}` — the ABAP name of the object being reviewed.
2. Header blockquote (see above).
3. `## Pre-check` — ATC and eligible unit-test status. Omit only under the rules above.
4. `## What changed` — 1–3 short bullets describing the intent and delta reviewed.
5. `## Findings at a glance` — compact table (see below).
6. `## Details` — one card per finding (see below), sorted CRITICAL → WARNING → INFO, then by finding ID.
7. `## Local Classes / Includes` — **mandatory for global classes** (see § *Local Classes / Includes*).
8. `## Verification gaps` — bullets; each starts with the artefact name and one-line reason. Omit the section only if there are no gaps.
9. `## Recommended next actions` — 2–5 imperative bullets ordered by priority.

Never emit any of these sections:

- No `## Verdict` section.
- No `## Rule coverage` section.
- No standalone `## Release gate` / `Release Gate verdict line` — the header line replaces it.

## Findings at a glance — table

```
| ID | Severity | Artifact | Location | Summary |
|----|----------|----------|----------|---------|
| F-1 | 🔴 CRITICAL | {{ABAP_NAME}} | Lines A-B (`method_name`) | One-line summary of the problem. |
```

Rules:

- `ID` — sequential `F-1`, `F-2`, … within a single per-object report. IDs are local to the report and are **not** reused across TR (each object starts from `F-1`).
- `Severity` — icon plus uppercase word (`🔴 CRITICAL`, `🟡 WARNING`, `🟢 INFO`).
- `Artifact` — format `{{ABAP_NAME}}`, e.g. `ZCL_EXAMPLE_HANDLER` or `Z_R_EXAMPLE_ROOT`. Do not print the virtual-FS filename, surrounding parentheses, or absolute paths in this field; retain the filename only as internal evidence for source retrieval and line verification.
- `Location` — format `Lines A-B (\`anchor\`)`. `anchor` is the enclosing method / determination / validation / entity behaviour block name. For class-level issues use `Lines A-B (class-level)`. For single-line issues collapse: `Line 42 (\`method_name\`)`.
- `Summary` — one sentence, imperative or descriptive. No code fences in this column.
- Sort by severity then by `ID`.

## Details — cards

One card per row of the glance table. Card template:

```
### F-1 · 🔴 CRITICAL · Short title

- **Artifact**: {{ABAP_NAME}}
- **Location**: Lines A-B (`method_name`)
- **Problem**: 1–3 sentences describing the defect and why it is wrong.
- **Impact**: 1 sentence, business or runtime consequence.
- **Fix**: 1–3 sentences describing the concrete fix. May include a short inline code snippet or a fenced block ≤ 15 lines.
- **Evidence** *(optional)*: quoted source excerpt ≤ 8 lines in a fenced block.
```

Rules:

- Card heading: `### F-N · <ICON SEVERITY> · <Short title>`. Short title ≤ 8 words.
- Same `Artifact` and `Location` format as the glance table (verbatim).
- Never include a `Rule:` attribute — internal category codes (`ARCH-01`, `RAP-03`, `NAME-06`, `LOC-*`, etc.) drive the rule pass but must not appear in the emitted card.
- Do not repeat the header line inside a card.
- If a finding spans multiple locations of the same artefact, list them inside `Location` joined by ` · ` (e.g. `Lines 42-58 (\`method_a\`) · Lines 120-134 (\`method_b\`)`).
- If a finding spans multiple artefacts (same root cause), list their ABAP object names inside `Artifact` joined by ` · ` and use `Location` `see per-artifact block below`, then add a sub-list one line per artefact.

## Finding IDs

- Format: `F-<positive integer>` starting at `F-1`, incrementing by `1`.
- Unique within one per-object report. Reused across reports (each report starts from `F-1`).
- No sub-IDs (`F-1a`), no gaps unless dedup removed an ID mid-review (leave the gap rather than renumber).

## Deduplication rules

Apply **before** rendering the glance table and the cards.

1. **Same location + same root cause** → merge into a single finding at the highest observed severity. Keep the most severe icon.
2. **Same root cause, different locations** → one finding with multiple entries in `Artifact` / `Location` joined by ` · `. Do not create two separate cards.
3. **A strictly resolved by fixing B** → drop A entirely; do not mention it.
4. **Cross-severity duplicates** — if the same defect is reported by two different rules at different severities, keep the higher severity and drop the lower.
5. Never write `Merged: F-x, F-y` traces. Merges are internal.

## Prohibited elements

None of the following may appear in any emitted report:

- Words `GO`, `NO-GO`, `CONDITIONAL GO`.
- Sections `## Verdict`, `## Release Gate`, `## Rule coverage`.
- `Rule:` attribute inside a finding card.
- `Merged:` / `Deduplicated:` traces.
- Internal category codes (`ARCH`, `RAP`, `NAME`, `PERF`, `CLEAN`, `CDS`, `TEST`, `DOC`, `CCORE`, `LOGIC`, `RUNTIME`, `EFFIC`, `LOC-*`, `ARCH-01`, `RAP-03`, `PERF-02`, etc.) in table cells or card fields. They live inside the workflow only.
- Emoji other than 🔴 / 🟡 / 🟢 as severity markers.

## Local Classes / Includes (mandatory for global classes)

Every review of a global ABAP class must include this section immediately after `## Details` and before `## Verification gaps`.

### Structure

```
## Local Classes / Includes

**Includes read:** `*.clas.definitions.abap` (N lines), `*.clas.implementations.abap` (N lines), `*.clas.macros.abap` (empty / N lines), `*.clas.testclasses.abap` (empty / N lines).

**Local classes inventoried:**

- `lcl_<name>` — short purpose, visibility (`CREATE PRIVATE FRIENDS …` / `INHERITING FROM …`), key methods
- `lcx_<name>` — local exception, parent class
- `lhc_<entity>` — RAP handler (when applicable), redefined methods listed
- `lsc_<entity>` — RAP saver (when applicable), redefined methods listed

### Local-class findings

Reuse the same glance table + card format as global findings. Finding IDs continue the same `F-N` sequence — do **not** restart numbering for locals. In the `Artifact` column, use the local-class name (e.g. `lcl_processor` or `lhc_Header`) instead of the global class name. `Location` still uses `Lines A-B (\`method_name\`)`; include filenames remain internal evidence and are omitted from the rendered `Artifact` field.
```

Rules:

- If the includes are empty stubs, replace the tables with a single paragraph:
  > `*.clas.definitions.abap` and `*.clas.implementations.abap` are empty stubs. No local-class findings.
- If an include cannot be read, do **not** write the stub paragraph; add a bullet under `## Verification gaps` naming the include and the reason.
- The header line counters at the top of the report include local-class findings.

### Special case — Behaviour Pools (`*.clas.abap = FOR BEHAVIOR OF …`)

- The global wrapper is empty by RAP convention; the entire RAP behaviour (`lhc_*`, `lsc_*`, helper `lcl_*`) lives in `*.clas.implementations.abap`.
- `## Findings at a glance` for the wrapper will normally be empty or contain only a documentation finding for the missing class-level ABAP-Doc.
- The substance of the review lives in `## Local Classes / Includes`.
- **Never** conclude *"BP is empty, all logic lives elsewhere"* without having read the implementations include first — that is a verification gap, not a finding.

## Consolidated Summary — `_summary.md`

Only for transports / packages / multi-object reviews. Structure:

1. `# Consolidated Summary — {{TR_NUMBER_OR_LABEL}}`
2. Header blockquote — aggregated counters (sum across all per-object reports).
3. `## Pre-check` — aggregated ATC and eligible unit-test status.
4. `## Scope` — 1–3 bullets: TR number, package(s), review date, reviewer.
5. `## Overview` — table:

   ```
   | Object | Type | 🔴 | 🟡 | 🟢 | Report |
   |--------|------|----|----|----|--------|
   | ZCL_EXAMPLE_HANDLER | Class | 1 | 2 | 0 | [zcl-example-handler.md](./zcl-example-handler.md) |
   | Z_R_EXAMPLE_ROOT    | CDS   | 0 | 1 | 1 | [z-r-example-root.md](./z-r-example-root.md) |
   ```

6. `## Cross-object themes` — 2–5 bullets grouping recurring root causes across objects (e.g. *"validation logic duplicated in three handlers"*).
7. `## Blockers` — bulleted list of every CRITICAL finding across the TR, format `- **{{OBJECT_NAME}}** · F-N · one-line summary · [details](./file.md#f-n)`.
8. `## Verification gaps` — aggregated gaps from all per-object reports, deduplicated.
9. `## Recommended next actions` — 3–7 imperative bullets ordered by priority.

Rules for `_summary.md`:

- Header rule identical to per-object reports: 🔴 if any CRITICAL across all objects, else 🟢. Never print the words `GO`, `NO-GO`, `CONDITIONAL GO`.
- Do not repeat per-object cards — link to the per-object file instead.
- Do not emit a `## Verdict` or `## Release Gate` section.

## File-path conventions

Applies when output mode is `file` or `both`. Determine current datetime in `YYYY-MM-DD_HH-MM` format.

| Review type | Path |
|---|---|
| Single object | `docs/code-reviews/<YYYY-MM-DD_HH-MM>_<kebab-object-name>.md` |
| Transport / package / multi-object | `docs/code-reviews/<TR-number-or-label>/` — one file per object (kebab-case name) + `_summary.md` |
| Pasted code / no name | `docs/code-reviews/<YYYY-MM-DD_HH-MM>_inline-review.md` |

Create the target folder if it does not exist.

## Wording rules

- Say `not verified` when a check was not executed.
- Say `verification gap` when evidence could not be collected.
- Do not say `passed` unless the output was observed.
- Do not hide assumptions inside findings; move them to `## Verification gaps` or `## Recommended next actions`.
- Never use future tense promises (`will be fixed`); use imperative for fixes (`Extract the SELECT before the loop`).
- Keep hypotheses out of `## Findings at a glance` and `## Details`. Strong-but-unproven signals go into `## Verification gaps` or, when the workflow allows, a separate `## Architectural suspicions / review leads` section (only if enabled by config).

## Excluded from review output — cross-file policy

Two check patterns must never emit a finding in the report, even if the underlying rule fires. They are false-positive-prone and are handled outside the review loop:

1. **Empty behaviour pool referenced by a BDEF outside the current change set.** When a behaviour pool wrapper is empty (`*.clas.abap` empty by RAP convention) and the BDEF that references it is not part of the reviewed transport / paste / object set, do **not** emit a `RAP-*` or `ARCH-*` finding about *"no handler binding"* — the handler lives in a sibling class not visible in the current scope.
2. **Naming inconsistency among sibling local behaviour-handler classes.** When two or more local classes (`lhc_<entity>`) inside the same behaviour pool have inconsistent affix / suffix conventions (e.g. one uses a variant token another does not), do **not** emit a `NAME-*` finding. Sibling handlers are named per RAP entity and the resulting inconsistency is structural, not stylistic.

The underlying rule descriptions in `references/rap-review.md` and `references/naming-convention.md` note the same exclusion.
