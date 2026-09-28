# Runtime-Safety Review Lens (RUNTIME)

This file is a **reasoning aid**, not a static rule catalog. It does **not** replace ATC. Use it during `SKILL.md` Phase 4 / Phase 5.b to predict short dumps, unhandled system exceptions, and LUW / lock leaks that ATC does not raise.

> Anything ATC already flags (dead code, obsolete syntax, DB access checks) is out of scope here — the pre-check block already reports the ATC verdict.

## What this lens looks for

**Realistic short-dump surface** — a specific input, timing, or error path that leads to an uncaught runtime exception (`CX_SY_*`), a hung lock, an open cursor, or a broken LUW.

## Reasoning procedure

For every dereference, dynamic access, arithmetic, cast, DB operation, or transactional statement, trace value provenance to the nearest guard. If a guard is missing on **any** reachable path, flag it.

### Focus areas

1. **Field-symbols**
   - Every `<fs>-comp` / `<fs>->m( )` access — is `<fs> IS ASSIGNED` guaranteed on this path?
   - `ASSIGN COMPONENT … TO <fs>` — is `sy-subrc = 0` checked immediately, or is `<fs>` used unconditionally after?
   - `ASSIGN dref->*` when `dref` may be initial.

2. **References**
   - `ref->m( )` after `READ TABLE`, `REDUCE`, `FILTER` returning `REF TO` — is `ref IS BOUND` verified?
   - Injected refs (constructor parameters, factory results) used without `IS BOUND` when the source can legally return `INITIAL`.

3. **Casts**
   - `CAST` / down-cast (`?=`) without `TRY … CATCH cx_sy_move_cast_error`.
   - `CAST` inside a chained expression where the enclosing method has no `RAISING cx_sy_move_cast_error`.

4. **Arithmetic**
   - Division / MOD with a variable divisor that lacks a `IF divisor <> 0` (or equivalent) guard on the same path.
   - Multiplication of two `P(N)` values whose product overflows the target field's precision.
   - `+ 1` on a counter that could wrap when the target type is bounded (e.g. `INT4` at maximum).

5. **Dynamic access**
   - `ASSIGN (name)`, `CALL METHOD (name)`, dynamic `SELECT` on a name built from external input — is the name validated?
   - `RTTI` navigation (`get_component`, `get_method`) with `sy-subrc` unchecked.

6. **Table access**
   - `READ TABLE itab INTO ls WITH KEY …` without a `sy-subrc` check when `ls` is used afterwards. (Uninitialized components can silently pass through.)
   - `SELECT SINGLE` used as if guaranteed to hit — `sy-subrc` ignored, target used as non-initial.

7. **Exception scoping**
   - `CATCH cx_root` in a broad `TRY` masking classified exceptions the caller relies on distinguishing (this is a *runtime* concern — behaviour on failure — distinct from CLEAN-03 which is about empty handlers).
   - `RAISE EXCEPTION` inside a method whose signature has no `RAISING` for that class — dumps as `CX_SY_NO_HANDLER` at the caller.
   - `MESSAGE … RAISING` where the exception is not declared in the interface.

8. **Cursors, locks, LUW**
   - `OPEN CURSOR` without a matching `CLOSE CURSOR` on **every** exit path (including `RAISE`).
   - `ENQUEUE_*` without a matching `DEQUEUE_*` on every exit path.
   - `COMMIT WORK` / `ROLLBACK WORK` inside a `LOOP`, or inside a RAP handler / determination / validation (RAP owns the LUW).
   - `WAIT UP TO … SECONDS` inside a RAP handler or a dialog transaction.

9. **String / numeric conversion**
   - `MOVE` / assignment from `STRING` to a numeric or shorter-length target without `TRY … CATCH cx_sy_conversion_no_number` / `cx_sy_arithmetic_error`.
   - `CONV n( … )` on user-supplied text.

10. **Recursion**
    - Recursion without an explicit depth cap or termination proof — potential stack overflow (`STACK_OVERFLOW`).

11. **Deep structures / dereferences**
    - `ls_deep-t_children[ 1 ]-comp` on a table that may be empty (`CX_SY_ITAB_LINE_NOT_FOUND`).
    - Chained `->` on results of getters returning `INITIAL`.

12. **RAP-specific transactional risks**
    - `MODIFY ENTITIES` inside a validation.
    - `COMMIT ENTITIES` outside the saver phase.
    - `RAISE SHORTDUMP` used as a control-flow tool.

## How to report a RUNTIME finding

- Name the **CX_SY_*** (or dump kind) that would occur.
- Name the **input / path** that leads there.
- Point to the exact line where the guard is missing.
- Severity guidance:
  - **CRITICAL** — a realistic production input dumps. State it.
  - **WARNING** — the guard is missing but the current caller happens to prevent the input; a future caller could break it.
  - **INFO** — cosmetic guard tightening (e.g. adding `IS BOUND` where the reference is provably bound from context).

## Do NOT do

- Do not repeat CLEAN-03 (empty CATCH) — that rule already fires there.
- Do not raise a finding for every unhandled `CX_ROOT` — only when the specific classified exception matters to the caller.
- Do not invent exception classes — cite ones actually raised by the SDK/API used.
- Do not flag `sy-subrc` after `TRY … ENDTRY` variants (`INSERT … ACCEPTING DUPLICATE KEYS`, `MODIFY ENTITIES`) that do not set `sy-subrc`.

## Category tag

Internal category: `RUNTIME`. Do **not** print the tag in the report. Findings appear in the standard `## Findings at a glance` / `## Details` sections.
