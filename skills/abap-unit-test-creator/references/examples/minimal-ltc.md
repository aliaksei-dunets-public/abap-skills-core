# Example: Minimal Local ABAP Unit Test Class

Use this example when the task needs a basic local test class structure and no special isolation framework is required.

This is an illustrative pattern only. Replace every `<...>` placeholder with identifiers verified from the source, repository metadata, project profile, or explicit user instruction.

```abap
"--- ILLUSTRATIVE EXAMPLE ONLY — replace all <...> with verified identifiers ---
CLASS ltc_<unit_name> DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO <class_under_test>.

    METHODS setup.

    METHODS <method_under_test>_<scenario> FOR TESTING.
ENDCLASS.

CLASS ltc_<unit_name> IMPLEMENTATION.
  METHOD setup.
    " Arrange shared per-test fixture here.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD teardown.
    " Clear per-test state here when needed.
  ENDMETHOD.

  METHOD <method_under_test>_<scenario>.
    " Arrange
    DATA <input> TYPE <input_type>.

    " Act
    DATA(<result>) = cut-><method_under_test>( <input> ).

    " Assert
    cl_abap_unit_assert=>assert_equals(
      exp = <expected_value>
      act = <result>
      msg = '<explain expected behavior>' ).
  ENDMETHOD.
ENDCLASS.
```

Usage rules:

- Keep one scenario per test method.
- Prefer explicit Arrange / Act / Assert comments for generated tests unless the project profile says otherwise.
- Do not instantiate the class under test with `NEW #( )` if its constructor requires verified dependencies.
- Do not copy placeholder names into final code.
