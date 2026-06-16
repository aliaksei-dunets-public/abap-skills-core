# Example: Extending an Existing Local Test Class

Use when source already contains a local test class and the user asks to add
coverage. Preserve existing structure; append the smallest required change.

```abap
"--- ILLUSTRATIVE PATCH SHAPE ONLY — use real existing class/method names ---
CLASS ltc_<existing_test_class> DEFINITION.
  PRIVATE SECTION.
    " Existing declarations stay unchanged.

    METHODS <method_under_test>_<new_scenario> FOR TESTING.
ENDCLASS.

CLASS ltc_<existing_test_class> IMPLEMENTATION.
  " Existing implementation stays unchanged.

  METHOD <method_under_test>_<new_scenario>.
    " Arrange — reuse existing builders/fakes/setup if they are sound.

    " Act

    " Assert
    cl_abap_unit_assert=>assert_equals(
      exp = <expected_value>
      act = <actual_value>
      msg = '<explain newly covered behavior>' ).
  ENDMETHOD.
ENDCLASS.
```

Rules:
- Do not rewrite unrelated tests or rename existing helpers unless required
  for compilation. Reuse existing builders/fakes.
- Add only support code the new scenario needs.
- If existing tests are unsafe or misleading, report that separately rather
  than making a broad rewrite.
