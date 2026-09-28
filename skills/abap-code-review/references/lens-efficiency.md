# Efficiency Review Lens (EFFIC)

This file is a **reasoning aid**, not a static rule catalog. It does **not** replace ATC. Use it during `SKILL.md` Phase 4 / Phase 5.b to spot waste, needless complexity, and duplicated work that the static rule files (`rules-clean-abap.md`, `rules-performance.md`) do not catch.

> If a static rule already covers the observation (`PERF-02` SELECT-in-LOOP, method exceeding the size limit configured for CLEAN, etc.), **do not** re-report it under EFFIC. Reference the existing rule ID and move on.

## What this lens looks for

**Irrational / suboptimal code** — the program is correct and reasonably fast for small data, but performs avoidable work, obscures intent, or scales poorly for reasons ATC cannot detect.

## Reasoning procedure

For every loop, expression tree, method boundary, and data flow, ask:

1. **Loop-invariant work**
   - Is any expression inside `LOOP … ENDLOOP` computed from values that do not change per iteration? (Hoist above the loop.)
   - Is a `READ TABLE … WITH KEY` inside the loop keyed on a value that never changes? (Read once before the loop.)
   - Is an internal-table sort/hash rebuilt every iteration?

2. **Redundant restatement**
   - `SORT` after `ORDER BY` on the same key — one of them is dead work.
   - `REFRESH` / `CLEAR` immediately before a full reassignment.
   - `DELETE ADJACENT DUPLICATES` after `SELECT DISTINCT`.
   - Explicit `INITIAL LINE` insert then `MODIFY` — construct the row directly with `VALUE #( )`.

3. **Over-wide SQL**
   - `SELECT` with a broad field list when only one or two fields are used. (Different from `PERF-01` which is "no field list at all".)
   - `SELECT … INTO TABLE @DATA(lt_full)` followed by a single `READ TABLE` on one key — a `SELECT SINGLE` with the needed fields is enough.
   - Materialising a whole table when a `FOR … IN SELECT` or `LOOP AT itab REFERENCE INTO` would stream.

4. **Wrong table type for the access pattern**
   - Repeated linear `READ TABLE WITH KEY …` on a `STANDARD` internal table inside a hot path — `SORTED` or `HASHED` scales O(log n) or O(1).
   - `INSERT LINES OF … INTO TABLE …` inside a `LOOP` on a `STANDARD` table with the same primary key semantics as a `SORTED` table — the sort work is duplicated per insert.

5. **Gratuitous complexity**
   - Nested `COND #( )` where a simple `IF/ELSE` is clearer.
   - `SWITCH #( )` on a boolean.
   - `REDUCE #( )` used where `SUM( )` in SQL or a single `COLLECT` in a loop would express the intent.
   - Pattern-match ladders re-implementing what `CORRESPONDING #( … MAPPING …)` already does.

6. **Pass-through and shim methods**
   - A public method that only forwards to a single private method with the same signature — remove the shim.
   - A "factory" method that hard-codes a single implementation and takes no configuration — call the class directly.
   - A `CONSTANTS`-only local class or interface with a single member — inline the value.

7. **Speculative generality**
   - Configuration parameters that have exactly one caller and one value.
   - Extensibility hooks (BADI, event) added "for the future" without a known future consumer.
   - Generic `data` parameters (`TYPE data`, `TYPE any`, `TYPE ref to data`) where a concrete typed parameter would work.

8. **Duplicated work between callers**
   - Two call sites both build the same lookup table before calling a method — the method should build (and cache) it itself.
   - Two methods that differ only in a boolean flag which switches large branches — split into two focused methods.

9. **Needless intermediate variables**
   - Local variable assigned once and used once — inline unless it clarifies a long expression.
   - Structure filled field-by-field via `MOVE` when `VALUE #( )` initialisation is available.

10. **Boolean flag parameter splitting the method**
    - Method with `iv_mode TYPE abap_bool` where the two branches share almost no code — this is two methods pretending to be one.

11. **Dead configuration surface**
    - `CLASS-DATA` initialised at declaration but never re-assigned and never referenced.
    - Unused optional parameters — either remove or use.

12. **Cache thrash**
    - Method builds an in-memory index / hash on every call, but the underlying data is stable across the transaction. Consider a `CLASS-DATA` singleton cache with an explicit invalidation contract (see LOGIC lens item 10 in `lens-logic.md`).

## How to report an EFFIC finding

- State the **cost delta** — "O(n²) → O(n) because …", or "one extra sort of ~N rows per call".
- State the **fix** in a single sentence — no rewrites, just the target pattern.
- Severity guidance:
  - **WARNING** — cost scales with production data volumes (loop over a business collection, per-request work).
  - **INFO** — cosmetic / small-constant waste, or a smell that clarifies intent without changing runtime cost.
  - **CRITICAL** — reserved for cases where the waste triggers a genuine defect (e.g. cache thrash that leads to inconsistent results). Rare; prefer `LOGIC` or `RUNTIME` when correctness is at stake.

## Boundary vs static rules

| Observation | Route to |
|---|---|
| `SELECT` inside `LOOP` | `PERF-02` (not EFFIC) |
| `SELECT *` / no field list | `PERF-01` (not EFFIC) |
| FAE without guard | `PERF-03` (not EFFIC) |
| Method too long | `CLEAN` size rule (not EFFIC) |
| `FORM` / `PERFORM` in new code | `CLEAN-01` (not EFFIC) |
| `MOVE-CORRESPONDING` | `CLEAN-04` (not EFFIC) |
| Field-symbol without `IS ASSIGNED` | `RUNTIME` lens |
| Wrong `CASE` branch reached | `LOGIC` lens |

## Do NOT do

- Do not suggest micro-optimisations without a scaling argument.
- Do not recommend a hashed/sorted table for a lookup executed once per transaction.
- Do not turn EFFIC findings into rewrites — one-sentence fix guidance only. Rewrites belong to `/refactor`.

## Category tag

Internal category: `EFFIC`. Do **not** print the tag in the report. Findings appear in the standard `## Findings at a glance` / `## Details` sections.
