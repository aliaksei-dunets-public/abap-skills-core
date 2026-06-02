# Review Scope Playbook

Use this guide to turn the user's request into a concrete review set.

## Scope Selection Rule

If the request does not say whether the review is for an object, package, transport request, or transport task, ask exactly one scoping question first.

## Object Review

Collect:

- the named object
- related includes or implementation parts
- related local test classes or test includes when present
- nearby referenced artifacts when they are required to validate impact or released API status

Inspect:

- active source
- changed logic paths
- tests that protect the changed behavior

Expected checks:

- syntax when available
- ABAP Unit for testable class logic
- references when dependency impact is unclear

## Package Review

Collect:

- reviewable code artifacts in the package
- changed or requested artifacts first when that information exists
- only related artifacts needed to understand the changed behavior

Inspect:

- classes, interfaces, programs, CDS, behavior definitions, behavior implementations, and tests

Expected checks:

- syntax for the reviewed slice when available
- ABAP Unit for changed classes
- ATC when the package slice can be checked meaningfully

Guardrail:

- do not review every object in a large package by default when the requested slice is narrower

## Transport Request Review

Collect:

- all tasks in the request
- all objects attached to those tasks
- related implementation and test artifacts for the changed objects

Inspect:

- source for each changed object
- cross-object behavior when the request changes interacting artifacts

Expected checks:

- ATC for the changed slice when available
- ABAP Unit for changed classes
- syntax or reference checks to resolve unclear dependencies

## Transport Task Review

Collect:

- the task's changed objects only
- related implementation and test artifacts

Inspect:

- task-local source changes
- contract and integration risks created by those changes

Expected checks:

- ABAP Unit for changed classes
- syntax or references when available
- ATC when task-local review can be executed

## Evidence Standard

- Read actual source before reporting findings.
- Inspect tests when changed logic should be covered.
- If a required artifact cannot be read or checked, record that as a verification gap.
