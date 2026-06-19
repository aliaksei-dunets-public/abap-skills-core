# Reporting Format

Return findings first. Keep the review concise, evidence-based, and severity-ordered.

## Severity Scale

Use exactly three severity levels across all confirmed findings:

- **CRITICAL** — likely defect, regression, data integrity issue, transaction risk, or contract break. Blocks transport release.
- **WARNING** — meaningful quality, compliance, maintainability, or Clean Core risk with moderate delivery impact. Reviewer discretion required.
- **INFO** — small clarity or convention issue with limited delivery risk. No release gate impact.

## Per-Object Findings Table

Use this exact structure for each reviewed object. For global ABAP classes the report MUST include a dedicated `## Local Classes / Includes` section (see below) before the Release Gate verdict line.

### Section order inside a per-class report

1. Header (object type, package, reviewer, date, active categories)
2. Global findings table (findings on the global class itself)
3. **`## Local Classes / Includes`** — mandatory for global classes; see structure below
4. Architectural suspicions / review leads (optional)
5. Verification gaps
6. Release Gate verdict line

### Findings table format

```
---

## [ObjectName]  [[ObjectType]]

| Severity | Category | Location | Rule ID | Finding & Suggested Fix |
|----------|----------|----------|---------|------------------------|
| CRITICAL | ARCH | method:VALIDATE_INPUT, line ~42 | ARCH-01 | Missing guard for initial key can create an inconsistent update path. Reject empty keys before any read or write and cover the branch with a unit test. |
| CRITICAL | PERF | method:METHOD_NAME, line ~N | PERF-02 | SELECT inside LOOP AT. Extract SELECT before loop; use FOR ALL ENTRIES IN with IS NOT INITIAL guard. |
| WARNING  | CLEAN | line ~78 | CLEAN-04 | MOVE-CORRESPONDING used. Replace with: result = CORRESPONDING #( source MAPPING target_field = source_field ). |
| INFO     | NAME | method:LOCK_ITEM | NAME-06 | Parameter LOCK_REASON should be renamed to I_LOCK_REASON. Exception applies if this is a RAP-generated parameter. |
```

Rules:
- Sort rows: CRITICAL first, then WARNING, then INFO.
- Location: use `method:<METHOD_NAME>` for method-level, `line ~N` for approximate line number, `global` for class-level issues.
- Category: use the category code (`ARCH`, `PERF`, `CLEAN`, `RAP`, and so on).
- Rule ID: use the concrete rule ID for rule-backed findings. For architecture-driven confirmed findings, use stable IDs like `ARCH-01`, `ARCH-02`, and so on.
- Finding & Suggested Fix: one sentence describing the defect or risk, one sentence with the concrete fix.
- Omit clean categories entirely — do not write "no issues found" per category.
- If the object is fully clean: write `✓ No findings from collected evidence.`

Only confirmed findings belong in this table. Do not place hypotheses, weak signals, or missing-evidence notes here.

## Local Classes / Includes (mandatory for global classes)

Every review of a global ABAP class must include a `## Local Classes / Includes` section that documents what was read in `*.clas.definitions.abap` and `*.clas.implementations.abap`. Place the section immediately before the Verification gaps / Release Gate block.

### Structure

```
---

## Local Classes / Includes

**Includes read:** `*.clas.definitions.abap` (N lines), `*.clas.implementations.abap` (N lines), `*.clas.macros.abap` (empty / N lines).

**Local classes inventoried:**

- `lcl_<name>` — short purpose, visibility (`CREATE PRIVATE FRIENDS …` / `INHERITING FROM …`), key methods
- `lcx_<name>` — local exception, parent class
- `lhc_<entity>` — RAP handler (when applicable), redefined methods listed
- `lsc_<entity>` — RAP saver (when applicable), redefined methods listed

### Local-class findings

| Severity | Category | Location | Rule ID | Finding & Suggested Fix |
|----------|----------|----------|---------|------------------------|
| CRITICAL | ARCH | `lcl_processor->reset` | LOC-ARCH-01 | Method body is empty; the saver's `cleanup_finalize` calls it expecting a reset. Implement `CLEAR queue. CLEAR mo_instance.`. |
| WARNING  | PERF | `lcl_cache->lookup`    | LOC-PERF-01 | Linear search over STANDARD TABLE. Convert to HASHED TABLE keyed by lookup field. |
```

### Rules

- Use the prefix `LOC-<CAT>-NN` for local-class rule IDs (e.g. `LOC-ARCH-01`, `LOC-RAP-03`, `LOC-CLEAN-02`) so they are visually separated from the global class's `ARCH-01`, `RAP-03`, etc.
- The `Location` column must point to the local class and method (e.g. `lcl_processor->queue_header`, `lhc_Header~Activate`).
- All severity, sort, and wording rules from the global findings table apply.
- If the includes are empty stubs, write a short stub paragraph instead of the table:
  > `## Local Classes / Includes` — `*.clas.definitions.abap` and `*.clas.implementations.abap` are empty stubs. No additional findings.
- If the includes could not be read, do **not** write the stub paragraph; record a verification gap instead.
- The Release Gate verdict at the end of the report must consider local-class findings together with global findings. CRITICAL findings inside locals are blockers in the same way as CRITICAL findings on the global class.

### Special case — Behavior Pools (`*.clas.abap = FOR BEHAVIOR OF …`)

The global wrapper is empty by RAP convention; the entire RAP behavior (`lhc_*`, `lsc_*`, helper `lcl_*`) lives in `*.clas.implementations.abap`. For a behavior pool:

- The Findings Table at section #2 will normally be empty or contain only the documentation finding *"wrapper has no class-level ABAP-Doc describing the included handlers"*.
- The substance of the review lives in the `## Local Classes / Includes` section.
- The Release Gate verdict is driven entirely by local-class findings.
- **Never** conclude *"BP is empty, all logic lives elsewhere"* without having read the implementations include first — that conclusion is a verification gap, not a finding.

## Consolidated Summary (multiple objects only)

After all per-object sections, add:

```
---

## Consolidated Summary

| Object | Type | CRITICAL | WARNING | INFO | Release Gate |
|--------|------|----------|---------|------|--------------|
| (DEMO)BP_I_CON_IP | Behavior Impl. | 1 | 2 | 0 | 🔴 NO-GO |
| (DEMO)I_CON_IP    | Interface View | 0 | 1 | 1 | 🟡 CONDITIONAL GO |

**Overall transport verdict:** 🔴 NO-GO — resolve all CRITICAL findings before releasing.
```

## Output Order

1. Per-object findings tables and verdict lines
2. Consolidated summary (multiple objects only)
3. `Architectural suspicions / review leads` when `ARCH` is active and there is at least one strong but unproven signal
4. `Suggested tests` when `TESTSUG` is active and there is at least one high-value recommendation
5. Open questions and assumptions
6. Verification gaps

## Optional Sections

### Architectural Suspicion / Review Lead

Include only when `ARCH` is active and the signal is useful but not fully proven.

Use this structure:

```
## Architectural suspicions / review leads

- [ObjectName] — The update path appears to duplicate validation logic from another class, but the second implementation was not available in the collected evidence. Compare both paths before changing behavior.
```

### Suggested Tests

Include only when `TESTSUG` is active and the recommendation protects a meaningful risk.

Use this structure:

```
## Suggested tests

- [ObjectName] — Add a unit test for the empty-key rejection path to prevent silent updates with initial identifiers.
```

## Wording Rules

- Say `not verified` when a check was not executed.
- Say `verification gap` when evidence could not be collected.
- Do not say `passed` unless the output was observed.
- Do not hide assumptions inside findings; move them to the assumptions section.
- Keep hypotheses out of the findings table.
