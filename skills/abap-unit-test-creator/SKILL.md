---
name: abap-unit-test-creator
description: >
  Use whenever the user wants to write, generate, extend, or fix ABAP Unit
  tests — for ABAP classes, local classes, RAP handlers, validations,
  determinations, savers, or any ABAP Cloud / S/4HANA behavior implementation.
  Trigger on phrases like "write a test", "add unit test", "cover this method",
  "isolate SQL", "mock this interface", "test this RAP behavior", "improve test
  coverage". Also trigger when the user pastes ABAP source and asks how to test
  it, even without explicit "unit test" wording.
---

# ABAP Unit Test Creator

Create, extend, or fix isolated ABAP Unit tests for ABAP classes, local
classes, and RAP behavior implementations. Inspect the production unit, ground
all identifiers, choose a DB-free isolation strategy, generate or update tests,
and verify the result when tools are available.

---

## Reference Loading

Do not load reference files before reading the source. Load only what matches
the signals below.

### Reference files

| File | Load when source contains… | …or task mentions |
|---|---|---|
| `references/rap-patterns.md` | `MODIFY ENTITIES`, `READ ENTITIES`, `FOR MODIFY/VALIDATE/DETERMINE/ACTION/SAVE`, `IF_ABAP_BEHV`; name ends in `_BEHV`/`_IMPL` | RAP, behavior, validation, determination, action, saver, EML |
| `references/isolation.md` | SQL, `INSERT/UPDATE/DELETE`, `CALL FUNCTION`, `AUTHORITY-CHECK`, `sy-datum/uzeit/uname`, `ENQUEUE_`, `NUMBER_GET_NEXT`, `INTERFACES IF_`, `TYPE REF TO IF_` | mock, fake, isolate, SQL, BAPI, RFC, external |
| `references/environment.md` | *(no code signal)* | Cloud, BTP, ABAP Cloud, public edition; or environment unknown and no project config |
| `references/coverage-checklist.md` | 2+ public methods with branching | coverage plan, edge cases, extend coverage |
| `references/authoring-gotchas.md` | `RAISING` clause; param typed against fixed-value domain; identifier near 30 chars | fixed value, raises, exception, name too long |

### Example files (load at most one per scenario)

| File | Load when |
|---|---|
| `references/examples/minimal-ltc.md` | No existing test class AND no dependency signals |
| `references/examples/interface-fake.md` | `TYPE REF TO IF_` AND project config does not require `cl_abap_testdouble` |
| `references/examples/testdouble-interface.md` | `TYPE REF TO IF_` AND config allows `cl_abap_testdouble`, OR task mentions call count, verify call, testdouble |
| `references/examples/osql-test-environment.md` | Direct `SELECT/INSERT/UPDATE/DELETE` on a transparent table |
| `references/examples/cds-test-environment.md` | `SELECT` from entity matching `_I_`, `_C_`, `_P_`, or `_R_` |
| `references/examples/rap-eml.md` | `rap-patterns.md` was loaded AND source contains EML |
| `references/examples/extend-existing-ltc.md` | Source already contains `CLASS ltc_` or `FOR TESTING` |
| `references/examples/friends-clause.md` | Method under test is `PRIVATE`/`PROTECTED` with no public seam, OR `CREATE PRIVATE` with static singleton needing reset, OR task mentions friends, private method, singleton reset |
| `references/examples/test-data-builder.md` | Same wide structure constructed in 3+ test methods |

---

## Workflow

### Step 1 — Load config

Read `configs/config.md` if it exists. If it links to `configs/conventions.md`
or other files, read those too. Use project-specific test class prefix,
allowed frameworks, FRIENDS policy, EML mode, etc.

### Step 2 — Obtain the source

Use pasted source if provided. Otherwise read `references/source-reader.md`
and follow the detection chain. Do not proceed without the actual
implementation source.

### Step 3 — Inspect the source

Identify: class / behavior pool name; public + protected methods (or RAP
handlers); dependencies (interfaces, concrete classes, static calls, SQL,
CDS, EML, FM, BAPI, HTTP, RFC, authorization, date/time/user, number range,
locks); existing test classes, fakes, or seams.

Do not guess identifiers.

### Step 4 — Load references

Apply the signal tables above. Load only matching files.

### Step 5 — Plan

Outline before generating: test class name (config prefix, default `ltc_`);
isolation strategy per dependency; methods/handlers to cover; scenarios per
method. If a dependency has no safe seam, report a testability blocker (see
`references/isolation.md` for the template) and skip it — do not generate
fragile tests.

### Step 6 — Generate

Structure: `class_setup`, `setup`, test methods, `teardown`, `class_teardown`.

Rules:
- Use only identifiers verified from source or loaded references.
- Assert with `cl_abap_unit_assert`.
- Do not call productive DB, RFC, BAPI, or external systems.
- Do not use `COMMIT WORK` / `COMMIT ENTITIES` unless the user explicitly
  requests an integration scenario.
- One behavior per test method. Name the method after the scenario.

### Step 7 — Verify and report

If tools are available, run the tests, fix errors, re-run until green. If
not, state explicitly that execution was unverified.

Report: what was tested; isolation strategy per dependency; testability
blockers; verification status. Do not omit blockers. Do not claim tests pass
without execution evidence.

---

## Output Rules

- Output ABAP code only (no prose inside code blocks). Exception: a
  testability blocker report is markdown, not code.
- Place tests in the test include of the production class. If inline, label
  the include type clearly.
- Do not modify production code unless the user asks for testability
  refactoring; if a minimal change is required for isolation, propose it
  separately.
