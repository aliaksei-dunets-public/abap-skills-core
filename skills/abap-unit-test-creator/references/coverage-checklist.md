# Coverage Checklist

Use when planning, extending, or auditing test coverage.

## Scenario checklist

For each method, handler, validation, determination, action, or behavior
operation, cover where applicable:

- success path; empty input; invalid input; missing dependency result;
- duplicate input; conflicting input; boundary values;
- exception path; message path;
- `failed` / `reported` / `mapped` content;
- no unintended persistence;
- dependency interaction result;
- dependency NOT called when validation fails early;
- ordering or aggregation behavior where relevant.

Do not add tests that execute code without meaningful assertions.

## Assertions

Use `cl_abap_unit_assert` with diagnostic messages. Prefer specific over
generic: `assert_equals`, `assert_initial`, `assert_not_initial`,
`assert_bound`, `assert_not_bound`, `assert_true`, `assert_false`, `fail`
for unreachable paths. Each assertion should identify the broken behavior.

## Value objects / data holders

For classes that hold data without external dependencies:

- Construct with known input, assert each readable attribute.
- Cover constructor defaults (no-argument construction).
- Cover each setter / factory that mutates state.
- Verify attribute independence (setting one does not affect others).
- Test observable state after construction or mutation, not getters in
  isolation. One test per meaningful state combination — not one per field.
