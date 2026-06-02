# Example: Extending an Existing Local Test Class

Use this pattern when the source already contains a local test class and the user asks to add missing coverage.

The agent should preserve existing structure and append the smallest required changes.

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
    " Arrange
    " Reuse existing builders/fakes/setup if they are sound.

    " Act

    " Assert
    cl_abap_unit_assert=>assert_equals(
      exp = <expected_value>
      act = <actual_value>
      msg = '<explain newly covered behavior>' ).
  ENDMETHOD.
ENDCLASS.
```

Usage rules:

- Do not rewrite unrelated tests.
- Do not rename existing helpers or fixtures unless required for compilation.
- Prefer reusing existing builders and fakes.
- Add only support code needed by the new test scenario.
- If existing tests are unsafe or misleading, report that separately before broad rewrites.
