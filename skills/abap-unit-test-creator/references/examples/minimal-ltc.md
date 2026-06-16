# Example: Minimal Local Test Class

Basic structure when no special isolation framework is needed. Replace every
`<...>` with verified identifiers.

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
    cut = NEW #( ).
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

Rules:
- One scenario per test method.
- Explicit Arrange / Act / Assert comments unless the project profile says
  otherwise.
- Do not `NEW #( )` if the constructor requires verified dependencies.
