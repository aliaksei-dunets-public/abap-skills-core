# Example: Local Test Data Builder

Use when test data construction repeats across multiple methods. A builder
centralises field assignments and makes intent visible.

Prefer a local builder when:
- the same entity structure is built in 3+ test methods, AND
- the entity has many fields but tests only vary a few, AND
- no project-wide builder already exists.

If a project-wide builder/factory exists, extend it instead.

```abap
"--- ILLUSTRATIVE EXAMPLE ONLY — replace all <...> with verified identifiers ---
CLASS ltd_<entity_name>_builder DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS constructor.

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

Use in tests:

```abap
METHOD <method>_valid_input.
  DATA(ls_input) = NEW ltd_<entity_name>_builder( )->build( ).

  DATA(lv_result) = cut-><method>( ls_input ).

  cl_abap_unit_assert=>assert_equals(
    exp = <expected_value>
    act = lv_result
    msg = 'Valid entity should produce expected result' ).
ENDMETHOD.

METHOD <method>_missing_field.
  DATA(ls_input) = NEW ltd_<entity_name>_builder( )
                     ->set_<field_1>( iv_value = '' )
                     ->build( ).

  DATA(lv_result) = cut-><method>( ls_input ).

  cl_abap_unit_assert=>assert_initial(
    act = lv_result
    msg = 'Missing field_1 should produce empty result' ).
ENDMETHOD.
```

Rules:
- Place the builder (`ltd_…_builder`) before the test class in the include.
- Defaults in the constructor; tests override only fields they care about.
- Builders produce data only — no assertion logic.
- Limit the builder to fields actually used; do not pre-populate every
  field of a wide structure.
- Use fluent chaining only when the project profile allows it.
