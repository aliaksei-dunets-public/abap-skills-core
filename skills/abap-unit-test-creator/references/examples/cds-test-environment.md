# Example: CDS Isolation with `cl_cds_test_environment`

Use when production reads CDS entities/views and the environment supports
CDS test doubles. Use only verified CDS, dependency, and row-type names.

```abap
"--- ILLUSTRATIVE EXAMPLE ONLY — replace all <...> with verified identifiers ---
CLASS ltc_<unit_name> DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CLASS-DATA cds_environment TYPE REF TO if_cds_test_environment.
    DATA cut TYPE REF TO <class_under_test>.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.
    METHODS <method_under_test>_<scenario> FOR TESTING.
ENDCLASS.

CLASS ltc_<unit_name> IMPLEMENTATION.
  METHOD class_setup.
    cds_environment = cl_cds_test_environment=>create(
      i_for_entity = '<cds_entity_name>' ).
  ENDMETHOD.

  METHOD class_teardown.
    cds_environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    cds_environment->clear_doubles( ).
    cut = NEW #( ).
  ENDMETHOD.

  METHOD <method_under_test>_<scenario>.
    " Insert with the row type of EACH doubled entity (one DATA per entity).
    DATA rows_<doubled_entity_1> TYPE STANDARD TABLE OF <doubled_entity_1>.

    rows_<doubled_entity_1> = VALUE #(
      ( <field_1> = <value_1>
        <field_2> = <value_2> ) ).

    cds_environment->insert_test_data( i_data = rows_<doubled_entity_1> ).

    DATA(result) = cut-><method_under_test>( <input> ).

    cl_abap_unit_assert=>assert_equals(
      exp = <expected_value>
      act = result
      msg = '<explain CDS-backed behavior>' ).
  ENDMETHOD.
ENDCLASS.
```

## What gets doubled (critical)

`cl_cds_test_environment=>create( i_for_entity = '<view>' )` does **NOT**
double `<view>` itself. By default (`i_select_base_dependencies = abap_false`)
it doubles:

1. The **immediate `select from` source** — the transparent table if the view
   selects directly from a DB table, or the intermediate CDS view if the view
   selects from another view (not the leaf at the bottom of a stack).
2. The **association target views** referenced in the projection — including
   targets used only via a `WHERE` filter on a target field.

**Insert with the row type of those doubled entities, not the view under
test.**

### `i_select_base_dependencies = abap_true`

Doubles the entire dependency tree (all CDS views and tables). Determine the
full set from view metadata and seed each entity actually read by the
production SELECT. Verify the doubled set before generating inserts.

### Worked example

```abap
define view <view_under_test>
  as select from <leaf_table_a> as Main
  association [0..1] to <target_view_b> as _Other
    on $projection.<key_a> = _Other.<key_b>
{ ... }
where _Other.<filter_field> = <constant>
```

Doubled set: `<leaf_table_a>` AND `<target_view_b>`. Insert pattern:

```abap
DATA leaf_rows   TYPE STANDARD TABLE OF <leaf_table_a>.    " DB column names — UPPER_CASE
DATA target_rows TYPE STANDARD TABLE OF <target_view_b>.   " View element names — camelCase if aliased

target_rows = VALUE #( ( <key_b> = '...' <filter_field> = <constant> ) ).
leaf_rows   = VALUE #( ( <key_a> = '...' <other_field> = '...' ) ).

cds_environment->insert_test_data( i_data = target_rows ).
cds_environment->insert_test_data( i_data = leaf_rows ).
```

## Common errors

| Error | Cause | Fix |
|---|---|---|
| `CX_CDS_FAILURE: The test double '<VIEW_UNDER_TEST>' not found` | Inserted with the view-under-test row type | Insert with the immediate `select from` source / association target instead |
| `CX_CDS_FAILURE: The test double '<LEAF_OF_ASSOC_TARGET>' not found` | Inserted into the leaf table behind an association target | Insert with the row type of the **target CDS view** itself |
| `Test double already created for <ENTITY> as part of UNIT testing of <VIEW>` | `create_for_multiple_cds` listed both view and its association target | Use plain `create( i_for_entity = <view> )` — the target is auto-doubled |
| `Test double already created for <SHARED_TABLE>` (multi-cds with two views) | Both views select from the same table | Pass only one view, share the seeded table; or create two separate environments |

## Diagnostic technique

Before generating inserts:
1. Open `<view_under_test>`.
2. Note the `select from <leaf_a>` table.
3. Note every `association ... to <other_view>` target.
4. Doubled set = `{ <leaf_a> } ∪ { <other_view>, ... }`.
5. Seed each doubled entity that participates in the WHERE/JOIN filter
   actually exercised by production code.

## Rules

- Only when production reads CDS entities/views.
- Verify exact row types before generating final code.
- Do not list a view's own association targets in `create_for_multiple_cds`.
- `create_for_multiple_cds` is correct for two or more **unrelated** CDS
  entities (neither is an association target of the other in the doubled
  set). For shared `select from` sources, see the Common errors table.
- `test_associations = abap_true` does not change which entities are doubled
  for modelled associations — but it **is** required when production
  navigates an association in ABAP (e.g. `_Other-SomeField` in SELECT or EML
  paths). Without it, association navigation returns empty even when the
  target double has data seeded.
