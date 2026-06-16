# Example: Local Fake for Interface Dependency

Use when production depends on an interface and behavior is simple. Prefer
existing project fakes/builders first.

```abap
"--- ILLUSTRATIVE EXAMPLE ONLY — replace all <...> with verified identifiers ---
CLASS ltd_<dependency_name> DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES <if_dependency>.

    DATA returned_value TYPE <return_type>.
    DATA call_count     TYPE i.
    DATA last_input     TYPE <input_type>.
ENDCLASS.

CLASS ltd_<dependency_name> IMPLEMENTATION.
  METHOD <if_dependency>~<method_name>.
    call_count = call_count + 1.
    last_input = <input_parameter>.
    result = returned_value.
  ENDMETHOD.
ENDCLASS.
```

Use in test class:

```abap
CLASS ltc_<unit_name> DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA fake_dependency TYPE REF TO <if_dependency>.
    DATA cut             TYPE REF TO <class_under_test>.

    METHODS setup.
    METHODS <method_under_test>_<scenario> FOR TESTING.
ENDCLASS.

CLASS ltc_<unit_name> IMPLEMENTATION.
  METHOD setup.
    fake_dependency = NEW ltd_<dependency_name>( ).
    cut = NEW <class_under_test>( io_dependency = fake_dependency ).
  ENDMETHOD.
```

Verify interaction:

```abap
cl_abap_unit_assert=>assert_equals(
  exp = 1
  act = fake_dependency->call_count
  msg = 'Dependency should be called once for valid input' ).
```

Rules:
- Track calls only when the interaction itself matters.
- Do not overfit one fake to one test if a fixed return value is enough.
- If production creates the dependency internally, report a blocker or
  recommend introducing a seam.
