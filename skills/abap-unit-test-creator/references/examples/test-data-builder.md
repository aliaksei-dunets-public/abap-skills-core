# Example: Local Test Data Builder

Use this pattern when test data construction is repetitive across multiple test
methods. A builder centralizes field assignments, reduces duplication, and makes
test intent visible.

Prefer a local builder class when:
- the same entity structure is constructed in three or more test methods;
- the production entity has many fields but tests only vary a few of them;
- a project-wide builder does not already exist for this entity.

If a project-wide builder or factory already exists, use that instead.

```abap
"--- ILLUSTRATIVE EXAMPLE ONLY — replace all <...> with verified identifiers ---

"--- Local builder: produces test instances of <entity_structure> ---
CLASS ltd_<entity_name>_builder DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS constructor.

    "--- Setter methods — each returns ME for fluent chaining ---
    METHODS set_<field_1>
      IMPORTING iv_value TYPE <field_1_type>
      RETURNING VALUE(ro_builder) TYPE REF TO ltd_<entity_name>_builder.

    METHODS set_<field_2>
      IMPORTING iv_value TYPE <field_2_type>
      RETURNING VALUE(ro_builder) TYPE REF TO ltd_<entity_name>_builder.

    METHODS build
      RETURNING VALUE(rs_result) TYPE <entity_structure>.

  PRIVATE SECTION.
    DATA ms_entity TYPE <entity_structure>.
ENDCLASS.

CLASS ltd_<entity_name>_builder IMPLEMENTATION.
  METHOD constructor.
    "--- Default values — override with set_* methods ---
    ms_entity-<field_1> = <sensible_default_1>.
    ms_entity-<field_2> = <sensible_default_2>.
  ENDMETHOD.

  METHOD set_<field_1>.
    ms_entity-<field_1> = iv_value.
    ro_builder = me.
  ENDMETHOD.

  METHOD set_<field_2>.
    ms_entity-<field_2> = iv_value.
    ro_builder = me.
  ENDMETHOD.

  METHOD build.
    rs_result = ms_entity.
  ENDMETHOD.
ENDCLASS.
```

## Usage inside a test class

```abap
CLASS ltc_<unit_name> DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO <class_under_test>.
    METHODS setup.
    METHODS <method>_valid_input   FOR TESTING.
    METHODS <method>_missing_field FOR TESTING.
ENDCLASS.

CLASS ltc_<unit_name> IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD <method>_valid_input.
    " Arrange — minimal fluent construction
    DATA(ls_input) = NEW ltd_<entity_name>_builder( )->build( ).

    " Act
    DATA(lv_result) = cut-><method>( ls_input ).

    " Assert
    cl_abap_unit_assert=>assert_equals(
      exp = <expected_value>
      act = lv_result
      msg = 'Valid entity should produce expected result' ).
  ENDMETHOD.

  METHOD <method>_missing_field.
    " Arrange — override one field to trigger the error path
    DATA(ls_input) = NEW ltd_<entity_name>_builder( )
                       ->set_<field_1>( iv_value = '' )
                       ->build( ).

    " Act
    DATA(lv_result) = cut-><method>( ls_input ).

    " Assert
    cl_abap_unit_assert=>assert_initial(
      act = lv_result
      msg = 'Missing field_1 should produce empty result' ).
  ENDMETHOD.
ENDCLASS.
```

## Usage Rules

- Place the builder class (`ltd_`) before the test class in the test-class
  include area.
- Provide sensible defaults in the constructor so each test only overrides
  the fields relevant to its scenario.
- Do not put assertion logic inside the builder — builders produce data only.
- Keep the builder limited to the fields actually used across tests; do not
  pre-populate every field of a wide structure.
- Use fluent chaining (`RETURNING VALUE(ro_builder) TYPE REF TO ...`) only when
  the project profile allows method chaining patterns.
- If a project-wide builder already exists, extend it rather than creating a
  duplicate local one.
