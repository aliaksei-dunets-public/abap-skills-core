# Reporting Format

Return findings first. Keep the review concise, evidence-based, and severity-ordered.

## Severity Scale

Use exactly three severity levels across all confirmed findings:

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
