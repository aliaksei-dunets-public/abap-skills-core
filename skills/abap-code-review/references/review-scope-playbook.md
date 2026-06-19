# Review Scope Playbook

Use this guide to turn the user's request into a concrete review set.

## Scope Selection Rule

If the request does not say whether the review is for an object, package, transport request, or transport task, ask exactly one scoping question first.

## Object Review

Collect:

- the named object
- related includes or implementation parts
- **for global ABAP classes — all sibling includes are mandatory:**
  - `*.clas.definitions.abap` (local type pool + local class `DEFINITION`s)
  - `*.clas.implementations.abap` (local class `IMPLEMENTATION`s; for RAP behavior pools this is where the entire `lhc_*` / `lsc_*` handler logic lives — the `*.clas.abap` wrapper is empty by convention and reading only the wrapper produces wrong verdicts)
  - `*.clas.macros.abap` (when present)
  - `*.clas.testclasses.abap` (when `TEST` is active)
- related local test classes or test includes when present
- nearby referenced artifacts when they are required to validate behavior, impact, released API status, or business flow consistency

Inspect:

- active source
- all four sibling includes for global classes (see above)
- changed logic paths
- tests that protect the changed behavior
- the smallest set of related objects needed to understand the contract

Expected checks:

- syntax when available
- ABAP Unit for testable class logic
- ATC check when review can be executed
- references when dependency impact is unclear

## Package Review

Collect:

- reviewable code artifacts in the package
- changed or requested artifacts first when that information exists
- only related artifacts needed to understand changed behavior, dependencies, and cross-object consistency

Inspect:

- classes, interfaces, programs, CDS, behavior definitions, behavior implementations, and tests

Expected checks:

- syntax for the reviewed slice when available
- ABAP Unit for changed classes

Guardrail:

- do not review every object in a large package by default when the requested slice is narrower
- stop expanding once the current evidence can explain the behavior or justify a verification gap

## Transport Request Review

Collect:

- all tasks in the request
- all objects attached to those tasks
- related implementation and test artifacts for the changed objects

Inspect:

- source for each changed object
- cross-object behavior when the request changes interacting artifacts
- related tests or support objects when they are needed to explain the changed contract

Expected checks:

- ABAP Unit for changed classes
- syntax or reference checks to resolve unclear dependencies

## Transport Task Review

Collect:

- the task's changed objects only
- related implementation and test artifacts

Inspect:

- task-local source changes
- contract and integration risks created by those changes
- related tests when they should protect changed logic

Expected checks:

- ABAP Unit for changed classes
- syntax or references when available

## Evidence Standard

- Read actual source before reporting findings.
- Inspect tests when changed logic should be covered.
- Pull related context only when it changes the review conclusion.
- Prefer a verification gap over a weak conclusion when a required artifact cannot be read or checked.
- Use architectural suspicions for strong but incomplete signals, not for routine uncertainty.
