# Example: CDS Isolation with `cl_cds_test_environment`

Use this example when production code reads from CDS entities/views and the target environment supports CDS test doubles.

Use only verified CDS names, dependency names, and row types.

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
    " Insert with the row type of each DOUBLED entity separately.
    " If only one entity is in the doubled set, one DATA declaration is enough.
    " If both a leaf table and an association target are doubled, declare one
    " variable per entity — see "What gets doubled" and the worked example below.
    DATA rows_<doubled_entity_1> TYPE STANDARD TABLE OF <doubled_entity_1>.
    " DATA rows_<doubled_entity_2> TYPE STANDARD TABLE OF <doubled_entity_2>.  " add if needed

    rows_<doubled_entity_1> = VALUE #(
      ( <field_1> = <value_1>
        <field_2> = <value_2> ) ).

    cds_environment->insert_test_data( i_data = rows_<doubled_entity_1> ).
    " cds_environment->insert_test_data( i_data = rows_<doubled_entity_2> ).  " add if needed

    DATA(result) = cut-><method_under_test>( <input> ).

    cl_abap_unit_assert=>assert_equals(
      exp = <expected_value>
      act = result
      msg = '<explain CDS-backed behavior>' ).
  ENDMETHOD.
ENDCLASS.
```

## What gets doubled (critical)

`cl_cds_test_environment=>create( i_for_entity = '<view>' )` does **NOT** create
a double for `<view>` itself. By default
(`i_select_base_dependencies = abap_false`) it creates doubles for:

1. The **immediate `select from` source** — if this is a transparent table, that table is doubled; if it is another CDS view (a stacked/composition view), that intermediate CDS view is doubled (not the leaf table at the bottom of the stack).
2. The **association target CDS view(s)** referenced in the view's projection
   (the framework treats those targets as doubled entities, even when the
   association is only used implicitly via a `WHERE` filter on a target field).

**Insert test data using the row type of those doubled entities, not the row
type of the view under test.**

### Non-default mode: `i_select_base_dependencies = abap_true`

When production code passes `i_select_base_dependencies = abap_true` to
`cl_cds_test_environment=>create`, the framework resolves and doubles the entire
dependency tree (all CDS views and tables in the hierarchy), not just the
immediate `select from` source. In this mode:

- Determine the full dependency tree from the view's metadata.
- Insert test data using the row type of each table/view that is actually read
  by the production SELECT — the set is wider than in default mode.
- The doubling scope change means any insert using a view's row type (rather
  than its leaf table) may now be correct or incorrect depending on where in
  the tree the framework placed the double.

If you encounter this flag in production code, verify the exact doubled set from
the environment metadata before generating insert statements.

### Worked example

A view with a join + filter via an association:

```abap
define view <view_under_test>
  as select from <leaf_table_a> as Main
  association [0..1] to <target_view_b> as _Other
    on $projection.<key_a> = _Other.<key_b>
{ ... }
where _Other.<filter_field> = <constant>
```

Doubled entities: `<leaf_table_a>` AND `<target_view_b>`.

Insert pattern:

```abap
DATA leaf_rows   TYPE STANDARD TABLE OF <leaf_table_a>.    " field names match the transparent table columns (UPPER_CASE)
DATA target_rows TYPE STANDARD TABLE OF <target_view_b>.   " field names match what the CDS view exposes — camelCase if the view uses aliases, UPPER_CASE if it exposes DB columns directly

target_rows = VALUE #( ( <key_b> = '...' <filter_field> = <constant> ) ).
leaf_rows   = VALUE #( ( <key_a> = '...' <other_field> = '...' ) ).

cds_environment->insert_test_data( i_data = target_rows ).
cds_environment->insert_test_data( i_data = leaf_rows ).
```

## Common errors and how to read them

| Error | Cause | Fix |
|---|---|---|
| `CX_CDS_FAILURE: The test double '<VIEW_UNDER_TEST>' not found` | You inserted with `STANDARD TABLE OF <view_under_test>` | Insert with the row type of the immediate `select from` source or association target instead |
| `CX_CDS_FAILURE: The test double '<LEAF_OF_ASSOC_TARGET>' not found` | You inserted into the leaf table behind an association target | Insert with the row type of the **target CDS view** itself — that is what got doubled |
| `Test double already created for <ENTITY> as part of UNIT testing of <VIEW>` | You called `create_for_multiple_cds` listing both the view and its association target | Use plain `create( i_for_entity = <view> )` only — the target is auto-doubled |
| `Test double already created for <SHARED_TABLE>` when using `create_for_multiple_cds` with two independent views | Both views select from the same underlying table; the framework tries to double it twice | Pass only one view to `create_for_multiple_cds` and handle the shared table via a single `insert_test_data` call, or create two separate `cl_cds_test_environment` instances |

## Diagnostic technique

When you do not yet know which entities the framework will double:

1. Open the source of `<view_under_test>`.
2. Note the `select from <leaf_a>` table name.
3. Note every `association ... to <other_view>` target name.
4. The doubled set = `{ <leaf_a> } ∪ { <other_view>, ... }`.
5. Generate test data with the row type of each doubled entity that participates
   in the WHERE/JOIN filter actually exercised by the production code.

## Usage rules

- Use this pattern only when the production code reads CDS entities/views.
- Do not use this pattern for direct SQL table access unless the source also uses CDS access.
- Verify exact row types before generating final code.
- Do **not** use `create_for_multiple_cds` to add a view's own association
  target — it is already doubled.
- `create_for_multiple_cds` is the right API when production code reads two or
  more CDS entities that are **not** related by association (neither is an
  association target of the other in the doubled set). If both views share a
  common `select from` source, see the Common errors table above.
- `test_associations = abap_true` does not change which entities are doubled for
  modeled associations — the association target view is doubled either way.
  However, `test_associations = abap_true` **is** required when production code
  navigates an association in ABAP (e.g. reads via `_Other-SomeField` in a
  SELECT or EML path) — without it, association navigation returns empty even
  when the target double has data seeded.
- If CDS dependencies cannot be identified, inspect metadata or report assumptions.
