---
name: abap-code-review
description: >
  Use when reviewing ABAP objects, packages, transport requests, or transport tasks
  for defects, contract risks, Clean Core issues, RAP issues, or naming problems
  before release or handoff. Trigger on: "review this ABAP", "check this class/CDS/behavior
  definition", "code review for transport", pasted ABAP/CDS source code, or any mention of
  an object that needs review.
---

# ABAP Code Review

Run a structured expert ABAP code review covering performance, Clean ABAP, naming conventions,
RAP correctness, CDS architecture, testability, and documentation. Produces a severity-graded
findings table and a release gate verdict per object.

This skill is assessment-only. It does not implement fixes.

---

## Phase 1 — Detect Input Mode and Load Config

Read `configs/config.md` for project-specific rules. If config.md references additional files
(e.g. `→ Read configs/naming.md for ...`), read those too before proceeding.

Examine the conversation to determine which mode applies. The modes are mutually exclusive and
checked in order:

**Mode A — Paste:** A code block (ABAP class, CDS view, BDEF, or any SAP source) is present
in the current conversation turn, or $ARGUMENTS is empty and no object name is given. Review
the pasted source directly. Use the object name from the CLASS/INTERFACE/DEFINE statement as
the report header, or `INLINE` if it cannot be determined.

**Mode B — Single ADT Object:** $ARGUMENTS contains a single object name
(e.g. `(DEMO)BP_I_CON_IP`). Invoke the `abap-vs-reader` skill to fetch the source, then
review it.

**Mode C — Transport / Object Set:** $ARGUMENTS contains a comma-separated list of object
names or a transport request number. For each object, invoke `abap-vs-reader` sequentially
to fetch its source. After all objects are fetched, run the full review and produce one
consolidated report.

Once you know the mode, proceed to Phase 2.

---

## Phase 2 — Collect Source

**Mode A:** The source is already available — proceed to Phase 3.

**Mode B:** Invoke the `abap-vs-reader` skill with the object name. If `abap-vs-reader`
cannot find the object, note it as `[SOURCE NOT FOUND]` in the report and continue.

**Mode C:** Invoke `abap-vs-reader` for each object in sequence. Collect all sources before
proceeding. For any object not found, note `[SOURCE NOT FOUND]` in its section.

---

## Phase 3 — Review Each Object

For every source collected, run all 7 categories below in order. Produce one finding table
per object. Only report rules where a violation is actually present — do not list "no issues
found" per rule, just omit clean rules. If the entire category is clean, omit that category
section entirely.

---

### Category 1 — Performance (PERF)

Examine all database access statements and data processing logic.

| Rule ID | What to look for | Severity |
|---------|-----------------|----------|
| PERF-01 | `SELECT *` or `SELECT ... INTO TABLE` without explicit field list | CRITICAL |
| PERF-02 | Any `SELECT`, `SELECT SINGLE`, or `OPEN CURSOR` statement inside a `LOOP AT ... ENDLOOP` block | CRITICAL |
| PERF-03 | `FOR ALL ENTRIES IN` not immediately preceded (within ~5 lines) by an `IF <table> IS NOT INITIAL` or `CHECK <table> IS NOT INITIAL` guard | CRITICAL |
| PERF-04 | Code that sorts or filters data where sort order matters but no `ORDER BY` clause is present on the SELECT | WARNING |
| PERF-05 | `SORT` or `DELETE ADJACENT DUPLICATES` on large internal tables when an `ORDER BY` clause in SQL or a CDS view could do this server-side | WARNING |
| PERF-06 | `BYPASSING BUFFER` used without an adjacent comment explaining why | WARNING |
| PERF-07 | `SUM`, `COUNT`, `MAX`, `MIN`, or `AVG` computed in ABAP via `LOOP AT` accumulation instead of `GROUP BY` / aggregate functions in the SQL SELECT | WARNING |

---

### Category 2 — Clean ABAP (CLEAN)

Examine code structure, OO design, and syntax modernity.

| Rule ID | What to look for | Severity |
|---------|-----------------|----------|
| CLEAN-01 | Any `FORM` or `PERFORM` statement in new code | CRITICAL |
| CLEAN-02 | `TABLES` statement (obsolete work area declaration) | CRITICAL |
| CLEAN-03 | `CATCH` block with no statements inside, or only a `RETURN`/`EXIT` with no message or logging | CRITICAL |
| CLEAN-04 | `MOVE-CORRESPONDING` — should be replaced by `CORRESPONDING #( source MAPPING ... )` | WARNING |
| CLEAN-05 | Non-constant `CLASS-DATA` (mutable global state) in a class definition | WARNING |
| CLEAN-06 | Multi-step procedural assignment that could be expressed with `VALUE #(...)`, `NEW #(...)`, `COND #(...)`, or `SWITCH #(...)` | WARNING |
| CLEAN-07 | Method implementation body longer than approximately 30 lines (count from `METHOD` to `ENDMETHOD`, excluding blank lines) | WARNING |
| CLEAN-08 | Commented-out blocks of production code (lines starting with `*` or `"` that contain ABAP statements, not explanatory prose) | INFO |
| CLEAN-09 | Assignment between structurally incompatible types without explicit `CONV` or `CAST` | WARNING |

---

### Category 3 — Naming Conventions (NAME)

Check all object and identifier names. Project-specific naming prefixes are loaded from config.

| Rule ID | What to look for | Severity |
|---------|-----------------|----------|
| NAME-01 | Object name not starting with the project namespace prefix — namespace prefix loaded from config | WARNING |
| NAME-02 | DDIC objects not following project domain/data-element/structure/table-type/table naming rules — patterns loaded from config | WARNING |
| NAME-03 | CDS/RAP objects not following project view naming rules — patterns loaded from config | WARNING |
| NAME-04 | Behavior Implementation Class not following project BP class naming pattern — pattern loaded from config | WARNING |
| NAME-05 | Local handler class not named `lhc_<Name>` or local saver class not named `lsc_<Name>` | INFO |
| NAME-06 | Method IMPORTING parameters not prefixed `I_`, EXPORTING `E_`, CHANGING `C_`, RETURNING `R_` — exception: RAP-generated parameter names must NOT be renamed | INFO |
| NAME-07 | Service Definition missing semantic name, or Service Binding missing protocol-type suffix — rules loaded from config | WARNING |
| NAME-08 | Mixed variable naming styles within the same class body | INFO |

---

### Category 4 — RAP Correctness (RAP)

Check RAP Behavior Implementation logic and authorization patterns.

| Rule ID | What to look for | Severity |
|---------|-----------------|----------|
| RAP-01 | Any direct `SELECT` or `SELECT SINGLE` from a DB table inside a validation method (`validate_*`) or determination method (`determine_*`) — must use `READ ENTITIES` instead | CRITICAL |
| RAP-02 | Standard managed CRUD operation (`create`, `update`, `delete`) overridden in a managed BO without a comment explaining why BAPI/legacy integration is needed | WARNING |
| RAP-03 | `get_global_authorization` method absent in a Behavior Implementation Class that has create/update/delete operations | CRITICAL |
| RAP-04 | Authorization check logic not delegated to the project auth-check class — auth-check class pattern loaded from config | WARNING |
| RAP-05 | Draft-enabled BO missing draft database table definition or missing draft action in BDEF | CRITICAL |
| RAP-06 | CDS entity appears in a Service Definition but has no corresponding Behavior Definition (`define behavior`) | CRITICAL |
| RAP-07 | Unmanaged RAP CRUD method (`create_*`, `update_*`, `delete_*`) with no comment indicating which BAPI or FM it delegates to | INFO |

---

### Category 5 — CDS Architecture (CDS)

Check CDS view structure, annotations, and layering.

| Rule ID | What to look for | Severity |
|---------|-----------------|----------|
| CDS-01 | Explicit `where mandt = ...` or `where mandt = $session.client` in a CDS view that is already client-dependent (redundant — the framework handles this) | WARNING |
| CDS-02 | `@UI.*` annotations present in an Interface View rather than in a Metadata Extension | WARNING |
| CDS-03 | `inner join` or `left outer join` used for a navigation path that is optional and accessed rarely — should be a CDS association instead | WARNING |
| CDS-04 | Association declared with cardinality `[1..1]` but the ON condition can result in 0 matching rows (no guaranteed FK constraint) | WARNING |
| CDS-05 | Projection View that has a `from` clause pointing directly to a DB table instead of an Interface View — violates the layering rule | CRITICAL |
| CDS-06 | `@OData.publish` annotation in a CDS view (service should be activated via admin transaction, not locally in ADT) | WARNING |

---

### Category 6 — Testability (TEST)

Check unit test presence, structure, and isolation quality.

| Rule ID | What to look for | Severity |
|---------|-----------------|----------|
| TEST-01 | Global class with business logic (validations, calculations, data transformations) but no `CLASS ... FOR TESTING` companion class in the test include | CRITICAL |
| TEST-02 | Inside a `FOR TESTING` class: direct `SELECT` from DB tables, or direct FM/BAPI calls without wrapping via `CL_ABAP_TESTDOUBLE` or SQL test environment (`CL_OSQL_TEST_ENVIRONMENT`) | CRITICAL |
| TEST-03 | Test method reads `SY-UNAME`, `SY-DATUM`, `SY-UZEIT`, or similar system fields directly (these must be injected or mocked for deterministic tests) | WARNING |
| TEST-04 | Method with `IF`/`CASE`/`WHEN` branching logic that has no corresponding test method exercising each branch | WARNING |
| TEST-05 | Production business logic placed inside a `FOR TESTING` class (test classes must not contain logic that runs in production) | WARNING |

---

### Category 7 — Documentation (DOC)

Check ABAP Docs and Knowledge Transfer document completeness.

| Rule ID | What to look for | Severity |
|---------|-----------------|----------|
| DOC-01 | Interface or global class with public methods that have no `"!` ABAP Doc comment above them | WARNING |
| DOC-02 | Interface method parameters (`IMPORTING`, `EXPORTING`, `RETURNING`) not individually documented with `"! @parameter <name>` ABAP Doc tags | INFO |
| DOC-03 | Behavior Definition object in review set but no reference to a KT (Knowledge Transfer) document in any accompanying comment or conversation context | WARNING |
| DOC-04 | Non-standard RAP Action (any `action` keyword in BDEF that is not `create`, `update`, `delete`, `edit`, `activate`, `discard`, `resume`) without a comment indicating where the KT document entry is | WARNING |
| DOC-05 | Object with `obsolete`, `old`, `deprecated`, `unused`, `todo remove`, or `to be deleted` in its name or a leading comment, but not assigned to the project obsolete package — obsolete package loaded from config | INFO |

---

## Phase 4 — Format Output

### Per-object table

Use this exact structure for each reviewed object:

```
---

## [ObjectName]  [[ObjectType]]

| Severity | Category | Location | Rule ID | Finding & Suggested Fix |
|----------|----------|----------|---------|------------------------|
| CRITICAL | Performance | method:METHOD_NAME, line ~N | PERF-02 | SELECT inside LOOP AT. Extract SELECT before loop; use FOR ALL ENTRIES IN with IS NOT INITIAL guard. |
| WARNING | Clean ABAP | line ~78 | CLEAN-04 | MOVE-CORRESPONDING used. Replace with: result = CORRESPONDING #( source MAPPING target_field = source_field ). |
| INFO | Naming | method:LOCK_ITEM | NAME-06 | Parameter LOCK_REASON should be renamed to I_LOCK_REASON. Exception applies if this is a RAP-generated parameter. |
```

- Sort rows: CRITICAL first, then WARNING, then INFO.
- Location: use `method:<METHOD_NAME>` for method-level, `line ~N` for approximate line number, or `global` for class-level issues.
- Finding & Suggested Fix: one sentence describing the violation, one sentence with the concrete fix.
- If the object is fully clean across all categories, write: `✓ No findings — object passes all checks.`

### Release gate verdict (per object)

Immediately after each object's table, add one line:

- **`🔴 NO-GO`** — one or more CRITICAL findings. Must be resolved before transport release.
- **`🟡 CONDITIONAL GO`** — no CRITICAL, but WARNING(s) present. Reviewer discretion; document accepted exceptions.
- **`🟢 GO`** — INFO only or clean. Ready for transport release.

### Consolidated summary (Mode C only — multiple objects)

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

---

## Phase 5 — Save Report

After producing the full output in the chat:

1. Determine the current datetime in `YYYY-MM-DD_HH-MM` format.
2. Derive a descriptive filename:
   - Single object: kebab-case of the object name (e.g. `bp-i-con-ip` from `(DEMO)BP_I_CON_IP`)
   - Multiple objects / transport: use TR number or user-supplied label from $ARGUMENTS (e.g. `transport-XYZK9A05GC`)
   - Pasted code / no name: `inline-review`
3. Create the directory `docs/code-reviews/` if it does not exist.
4. Write the complete report (identical to the chat output) to:
   `docs/code-reviews/<YYYY-MM-DD_HH-MM>_<descriptive-name>.md`
5. Confirm the saved path at the end of your response:
   > Report saved: `docs/code-reviews/2026-05-13_14-30_bp-i-con-ip.md`

---

## References

- Read `references/naming-convention.md` for generic naming baseline principles.
- Read `references/clean-core.md` for released API and upgrade-safe design guidance.
- Read `references/reporting-format.md` for output structure and severity wording rules.
- Read `references/review-scope-playbook.md` for scope collection playbook (object/package/TR/task).
- Read `references/best-practices.md` for review priority order and engineering risk heuristics.
- Read `references/rap-review.md` for RAP contract, EML, and handler/saver review details.
