# Example: Accessing Private Members with FRIENDS Clause

Use this pattern when the method under test is private or protected and cannot be
reached through the public interface. This is an on-premise / S/4HANA on-premise
pattern. Do not use in ABAP Cloud unless the project profile explicitly allows it.

Only use FRIENDS when direct method invocation is genuinely the best test strategy
and the production class cannot be reasonably refactored to expose a testing seam.

```abap
"--- ILLUSTRATIVE EXAMPLE ONLY — replace all <...> with verified identifiers ---

"--- Production class (abbreviated) ---
CLASS <class_under_test> DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PRIVATE SECTION.
    METHODS <private_method>
      IMPORTING iv_input TYPE <input_type>
      RETURNING VALUE(rv_result) TYPE <result_type>.
ENDCLASS.

"--- Local test class: declares friendship with the production class ---
CLASS ltc_<unit_name> DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO <class_under_test>.

    METHODS setup.
    METHODS <private_method>_<scenario> FOR TESTING.
ENDCLASS.

"--- Production class definition must name the test class as FRIENDS ---
CLASS <class_under_test> DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  FRIENDS ltc_<unit_name>.          "<<< Add this line to production class
  ...

CLASS ltc_<unit_name> IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD <private_method>_<scenario>.
    " Arrange
    DATA(lv_input) = <test_input_value>.

    " Act — direct call to private method via friendship
    DATA(lv_result) = cut-><private_method>( lv_input ).

    " Assert
    cl_abap_unit_assert=>assert_equals(
      exp = <expected_value>
      act = lv_result
      msg = '<describe expected private-method behavior>' ).
  ENDMETHOD.
ENDCLASS.
```

## When to Use

- The logic inside the private method is complex enough to warrant direct test coverage.
- The method has multiple branches or error paths that are hard to trigger through the
  public API alone.
- The project profile confirms FRIENDS clause is allowed.
- S/4HANA on-premise or S/4HANA Cloud Private Edition environment.

## When NOT to Use

- ABAP Cloud or S/4HANA Cloud Public Edition (unless project profile explicitly allows it).
- The private method can be reached indirectly through a public method with
  reasonable test setup.
- The FRIENDS clause would require modifying a production class that is in a
  released or transport-locked package.
- The private method belongs to a third-party or SAP standard class.

## Usage Rules

- The `FRIENDS` declaration must be added to the production class definition —
  the test class cannot grant itself friendship unilaterally.
- List only the test class names that genuinely need access.
- Do not use FRIENDS as a shortcut to bypass refactoring. Prefer exposing a
  testing seam through a public factory method, injection, or interface when feasible.
- Remove the FRIENDS clause if the test class is deleted or renamed.
