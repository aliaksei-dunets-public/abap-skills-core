# Reporting Format

Return findings first. Keep the review concise, evidence-based, and severity-ordered.

## Severity Scale

Use exactly three severity levels across all rule categories:

- **CRITICAL** — likely defect, regression, data integrity issue, transaction risk, or contract break. Blocks transport release.
- **WARNING** — meaningful quality, compliance, maintainability, or Clean Core risk with moderate delivery impact. Reviewer discretion required.
- **INFO** — small clarity or convention issue with limited delivery risk. No release gate impact.

## Per-Object Findings Table

Use this exact structure for each reviewed object:

```
---

## [ObjectName]  [[ObjectType]]

| Severity | Category | Location | Rule ID | Finding & Suggested Fix |
|----------|----------|----------|---------|------------------------|
| CRITICAL | Performance | method:METHOD_NAME, line ~N | PERF-02 | SELECT inside LOOP AT. Extract SELECT before loop; use FOR ALL ENTRIES IN with IS NOT INITIAL guard. |
| WARNING  | Clean ABAP | line ~78 | CLEAN-04 | MOVE-CORRESPONDING used. Replace with: result = CORRESPONDING #( source MAPPING target_field = source_field ). |
| INFO     | Naming     | method:LOCK_ITEM | NAME-06 | Parameter LOCK_REASON should be renamed to I_LOCK_REASON. Exception applies if this is a RAP-generated parameter. |
```

Rules:
- Sort rows: CRITICAL first, then WARNING, then INFO.
- Location: use `method:<METHOD_NAME>` for method-level, `line ~N` for approximate line number, `global` for class-level issues.
- Finding & Suggested Fix: one sentence describing the violation, one sentence with the concrete fix.
- Omit clean categories entirely — do not write "no issues found" per category.
- If the object is fully clean: write `✓ No findings — object passes all checks.`

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
3. Open questions and assumptions
4. Verification gaps

## Wording Rules

- Say `not verified` when a check was not executed.
- Say `verification gap` when evidence could not be collected.
- Do not say `passed` unless the output was observed.
- Do not hide assumptions inside findings; move them to the assumptions section.
