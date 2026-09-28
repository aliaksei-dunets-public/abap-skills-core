# Logic Review Lens (LOGIC)

This file is a **reasoning aid**, not a static rule catalog. It does **not** replace ATC. Use it during `SKILL.md` Phase 4 (architecture-first) and Phase 5.b (lens pass) to reason about correctness beyond what a static checker can see.

> Static rules that ATC already covers (obsolete statements, unreachable statements, DB access rules, empty CATCH) must NOT be duplicated here — Phase 0.5 already reports the ATC verdict.

## What this lens looks for

**Hidden logical errors** — the code compiles, activates, and ATC is silent, but a realistic input produces a wrong result, a silently skipped branch, or a stale value.

## Reasoning procedure (apply to every method / form / block)

For each control-flow branch, ask **all** of the following before accepting the code as correct:

1. **Guard direction** — is the predicate testing the right side?
   - `IS INITIAL` vs `IS NOT INITIAL`, `IS BOUND` vs `IS NOT BOUND`, `= abap_true` vs `= abap_false`, `<>` vs `=`, `LT` vs `LE`.
   - Trace at least one input where the code enters the "then" branch — is it the intended input?

2. **Guard scope** — does the guard actually cover the operation it protects?
   - `IF a IS BOUND. ... some_other_ref->m( ). ENDIF.` — wrong reference tested.
   - `IF <fs> IS ASSIGNED. ... <fs2>-comp = ... ENDIF.` — wrong field-symbol tested.

3. **Ordering assumptions** — does the code rely on an order that the source does not guarantee?
   - `SELECT` without `ORDER BY` used as if sorted.
   - `LOOP AT itab` after a `SORT` that omitted a needed key column.

4. **Enum / domain exhaustiveness**
   - `CASE` on a domain-like value without `WHEN OTHERS` → adding a new value silently skips logic.
   - `IF … ELSEIF …` chain without a final `ELSE` where the caller assumes a value was assigned.

5. **Reachability**
   - Is any branch unreachable given the guards above it? (`ELSEIF` after an exhaustive `IF/ELSE`.)
   - Is any branch tautological — always true / always false given the enclosing predicate?

6. **Return-value contract**
   - Does every path assign the `RETURNING`/`EXPORTING` parameter?
   - Are there paths where the parameter keeps its INITIAL value while the caller expects a non-INITIAL result?

7. **Off-by-one / boundary values**
   - `LOOP AT itab FROM idx TO idx + n` — is `idx + n` `≤ lines( itab )`?
   - `READ TABLE itab INDEX 1` on a possibly empty table.
   - `sy-tabix` / `sy-index` used after a nested statement that resets it (nested `LOOP`, `SELECT`).

8. **Boolean flip**
   - `xsdbool( a <> b )` where `= b` is intended (typical when a constant is `abap_false` and the negation was refactored).
   - Result of a boolean method call negated once too many.

9. **Silent fallthroughs**
   - Method returns `INITIAL` when nothing matches — is that the caller's contract, or should it raise?
   - Empty `CATCH` for a classified exception may already be caught by CLEAN-03; **but** a `CATCH cx_root` swallowing a specific classified exception is a *logic* problem — the caller no longer sees the failure mode it expects.

10. **State mutation across iterations**
    - `LOOP AT itab INTO ls_row. ...` — is the modified `ls_row` written back? (`MODIFY itab FROM ls_row` missing, or the loop should be `REFERENCE INTO`.)
    - A `CLASS-DATA` / singleton mutated inside a per-request handler without invalidation.

11. **Dedup by insufficient key**
    - `SORT + DELETE ADJACENT DUPLICATES COMPARING …` where `COMPARING` omits a column that distinguishes rows the business considers distinct.
    - `INSERT … INTO TABLE …` on a `HASHED`/`SORTED` table where a semantic-duplicate silently overwrites.

12. **Comment drift**
    - Only report when the comment states a *concrete* behaviour that the code demonstrably violates. Vague drift ("outdated comment") is not a finding.

## How to report a LOGIC finding

- Name the **input** that triggers the wrong outcome. If you cannot name one, downgrade to WARNING or move to `## Architectural suspicions`.
- State **actual result** and **expected result** in the Problem field.
- Reference the exact guard/branch by line number.
- Severity guidance:
  - **CRITICAL** — a plausible production input produces a wrong result, a wrong branch, or a silently skipped mandatory step.
  - **WARNING** — the pattern is fragile / a future value would break it, but no current input is known.
  - **INFO** — comment drift, cosmetic guard redundancy that does not affect behaviour.

## Do NOT do

- Do not restate CLEAN-03 (empty CATCH), CLEAN-09 (implicit conversion), or PERF-* findings under LOGIC.
- Do not raise LOGIC findings on stylistic negation preference alone.
- Do not report an "IS NOT ASSIGNED" concern when the field-symbol was assigned unconditionally two lines above.
- Do not invent inputs — inputs must be plausible against the class contract you can see in the code.

## Category tag

Internal category: `LOGIC`. Do **not** print the tag in the report. Findings appear in the standard `## Findings at a glance` / `## Details` sections defined in `references/reporting-format.md`.
