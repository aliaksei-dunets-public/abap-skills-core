# RAP Review Rules (RAP)

Use this reference when the review touches RAP Behavior Definitions, Behavior Implementations, handlers, savers, projections, actions, determinations, or validations.

## Rules

| Rule ID | What to check | Severity |
|---------|--------------|----------|
| RAP-01 | Direct `SELECT` or `SELECT SINGLE` from a DB table inside a `validate_*` or `determine_*` method — must use `READ ENTITIES` instead | CRITICAL |
| RAP-02 | Standard managed CRUD operation (`create`, `update`, `delete`) overridden in a managed BO without a comment explaining why BAPI/legacy integration is needed | WARNING |
| RAP-03 | `get_global_authorization` method absent in a Behavior Implementation Class that has `create`, `update`, `delete`, `execute` (Actions), or `edit` (Draft) operations — check the BDEF for all operation types | CRITICAL |
| RAP-04 | Authorization check logic not delegated to the project auth-check class (`auth_check_class_pattern` from config) | WARNING |
| RAP-05 | Draft-enabled BO missing draft database table definition or missing draft action in BDEF | CRITICAL |
| RAP-06 | CDS entity appears in a Service Definition but has no corresponding Behavior Definition (`define behavior`) — may co-occur with CDS-05; report both, they describe different problems | CRITICAL |
| RAP-07 | Unmanaged RAP CRUD method (`create_*`, `update_*`, `delete_*`) with no comment indicating which BAPI or FM it delegates to | INFO |

> **Note on RAP-01 + PERF-02:** When the SELECT inside `validate_*`/`determine_*` is also inside a LOOP, report both RAP-01 and PERF-02. They describe different problems: RAP-01 = wrong access pattern; PERF-02 = performance consequence.

## Contract Checks

Review whether:

- `%control` is used consistently for changed fields.
- EML operations match the intended behavior contract.
- Validations reject invalid state early enough.
- Determinations do not silently overwrite user intent without contract support.
- Reported and failed messages are propagated coherently.

## Handler and Saver Risks

Flag additionally (as WARNING) when:

- Message propagation is missing from validation or action logic.
- Save-sequence assumptions can create inconsistent state.
- Handler logic mixes responsibilities in a way that hides contract boundaries.
