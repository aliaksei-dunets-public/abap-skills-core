# Coverage Checklist for ABAP Unit Test Authoring

Use this reference when building a coverage plan, extending existing coverage, or
deciding which scenarios to test.

## Core Coverage Checklist

For each relevant method, handler, validation, determination, action, or behavior
operation, cover where applicable:

- successful path;
- empty input;
- invalid input;
- missing dependency result;
- duplicate input;
- conflicting input;
- boundary values;
- exception path;
- message path;
- `failed` response content;
- `reported` response content;
- `mapped` response content;
- no unintended persistence;
- dependency interaction result;
- dependency not called when validation fails early;
- ordering or aggregation behavior where relevant.

Do not add low-value tests that only execute code without meaningful assertions.

## Assertion Rules

Use `cl_abap_unit_assert` with meaningful diagnostic messages.

Prefer specific assertions:

- `assert_equals`;
- `assert_initial`;
- `assert_not_initial`;
- `assert_bound`;
- `assert_not_bound`;
- `assert_true`;
- `assert_false`;
- `fail` for unreachable paths.

Avoid generic assertions when a more precise assertion is possible.

Every assertion should help identify the broken behavior.

## Value-Object and Data-Holder Pattern

For classes that hold data without external dependencies (value objects, data
containers, configuration holders), the test pattern is:

- Construct the object with known input values.
- Assert each readable attribute individually with `assert_equals`.
- Cover the constructor's default values (no-argument construction).
- Cover each setter or factory method that changes internal state.
- Verify that attributes are independent — setting one does not affect others.

Do not test getters in isolation; test the observable state of the object as a
whole after construction or mutation. One test method per meaningful state
combination is sufficient — do not generate one method per field.
