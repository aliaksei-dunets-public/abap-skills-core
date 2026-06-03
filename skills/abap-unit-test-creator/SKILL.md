---
name: abap-unit-test-creator
description: >
  Use this skill whenever the user wants to write, generate, extend, or fix
  ABAP Unit tests — including tests for ABAP classes, local classes, RAP
  handlers, validations, determinations, savers, or any ABAP Cloud / S/4HANA
  behavior implementation. Trigger on phrases like "write a test", "add unit
  test", "cover this method", "isolate SQL", "mock this interface", "test this
  RAP behavior", "improve test coverage", or similar wording. Also trigger when
  the user pastes ABAP source and asks how to test it, even without explicit
  "unit test" wording.
---

# ABAP Unit Test Creator

## Purpose

Create, extend, or fix isolated ABAP Unit tests for ABAP classes, local classes,
and RAP behavior implementations.

This skill is optimized for AI-agent usage. The agent must inspect the production
unit, ground all identifiers, map dependencies internally, choose a DB-free
isolation strategy, generate or update tests, and verify the result when tools
are available.

The goal is to produce tests that are isolated, meaningful, maintainable,
compatible with the target ABAP environment, and honest about assumptions and
verification status.

---

## When to Read References

**Do not load reference files before reading the source code.**

Load only what is needed. After obtaining the source, scan it for the signals
below and load the matching files. Read `configs/conventions.md` first
if it exists and contains project-specific values.

### Reference Files — Signal Table

| Reference file | Load when source contains… | …or task context contains |
|---|---|---|
| `references/rap-patterns.md` | `MODIFY ENTITIES`, `READ ENTITIES`, `FOR MODIFY`, `FOR VALIDATE`, `FOR DETERMINE`, `FOR ACTION`, `FOR SAVE`, `IF_ABAP_BEHV` | "RAP", "behavior", "validation", "determination", "action", "saver", "EML"; object name contains `_BEHV`, `_IMPL` |
| `references/isolation.md` | `SELECT … FROM`, `INSERT`, `UPDATE`, `DELETE`, `CALL FUNCTION`, `AUTHORITY-CHECK`, `sy-datum`, `sy-uzeit`, `sy-uname`, `ENQUEUE_`, `NUMBER_GET_NEXT`, `DATA … TYPE REF TO IF_`, `INTERFACES IF_` | "mock", "fake", "isolate", "SQL", "BAPI", "RFC", "external" |
| `references/environment.md` | *(no code signal — use context only)* | "Cloud", "BTP", "ABAP Cloud", "public edition"; or environment cannot be determined and project config is absent |
| `references/coverage-checklist.md` | 2+ public methods with branching (`IF`, `CASE`, `LOOP`) | "what to test", "coverage plan", "edge cases", "extend coverage" |

### Example Files — Signal Table

Load only the one example that matches. Do not load multiple examples speculatively.

| Example file | Load when |
|---|---|
| `references/examples/minimal-ltc.md` | No existing test class AND no dependency signals found |
| `references/examples/interface-fake.md` | `DATA … TYPE REF TO IF_` in source AND project config does not require `cl_abap_testdouble` |
| `references/examples/testdouble-interface.md` | `DATA … TYPE REF TO IF_` AND config allows `cl_abap_testdouble`, OR task mentions "call count", "verify call", "testdouble" |
| `references/examples/osql-test-environment.md` | `SELECT`/`INSERT`/`UPDATE`/`DELETE` against a transparent table |
| `references/examples/cds-test-environment.md` | `SELECT` from an entity whose name matches `_I_`, `_C_`, `_P_`, or `_R_` naming pattern |
| `references/examples/rap-eml.md` | `rap-patterns.md` was loaded AND source contains EML statements |
| `references/examples/extend-existing-ltc.md` | Source already contains a local test class (`CLASS ltc_` or `FOR TESTING`) |

---

## Workflow

### Step 1 — Obtain the source

If the user provides pasted source code, use it directly.

If the user provides an object name, read `references/source-reader.md` and
follow the detection chain to fetch the source.

Do not proceed without reading the actual implementation source.

### Step 2 — Inspect the source

Read the full source. Identify:

- the class or behavior pool name;
- public and protected methods (or RAP handler methods);
- dependencies (interfaces, concrete classes, static calls, SQL, CDS, EML, FM,
  BAPI, HTTP, RFC, authorization, date/time/user, number range, lock objects);
- existing local test classes;
- existing seams, fakes, or injection points.

Do not guess method names, field names, parameter names, or table names.

### Step 3 — Load references

Apply the signal tables above. Load only the files that match. Do not
speculatively load all references.

### Step 4 — Plan the test structure

Before generating code, outline:

- the test class name (prefix from project config, default `ltc_`);
- the isolation strategy per dependency;
- which methods or handlers to cover;
- which scenarios to test per method.

If a dependency cannot be isolated, report a testability blocker (see
`references/isolation.md` for format) and stop for that dependency.

### Step 5 — Generate tests

Follow TDD structure: `class_setup`, `setup`, test methods, `teardown`,
`class_teardown`.

Rules:
- Use only identifiers verified from the source or loaded reference files.
- Use `cl_abap_unit_assert` for all assertions.
- Do not call productive DB, RFC, BAPI, or external systems.
- Do not use `COMMIT WORK` or `COMMIT ENTITIES` unless the user explicitly
  requests an integration-like scenario.
- Keep each test method focused on one behavior.
- Name test methods after the scenario, not the implementation step.

### Step 6 — Verify

If tools are available:
- run the generated tests;
- report results;
- fix compilation or runtime errors;
- re-run until tests pass.

If tools are not available, state clearly that execution was not verified and
list any assumptions made.

### Step 7 — Report

State:
- what was tested (class, methods, scenarios);
- isolation strategy used per dependency;
- any testability blockers found;
- verification status (run result or unverified).

Do not omit blockers. Do not claim tests pass without execution evidence.

---

## Output Rules

- Output ABAP code only — no explanatory prose inside code blocks.
- Place the test class in the test include of the production class when writing
  to file. If writing inline, label the include type clearly.
- Do not modify production code unless the user explicitly asks for a
  refactoring to improve testability.
- If production code must change to enable isolation, propose the minimal change
  as a separate suggestion, not as part of the test output.
