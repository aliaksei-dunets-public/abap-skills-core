# abap-code-review — Config Template

## Required Fields (must be in configs/config.md or linked files)

- `primary_namespace` — ABAP namespace prefix for NAME-01 check (e.g. `/DEMO/`)
- `ddic_naming_rules` — Naming patterns for Domain, Data Element, Structure, Table Type, DB Table
- `cds_naming_rules` — Naming patterns for Interface View, Projection View, Base View, Draft table, TP view
- `bp_class_pattern` — Behavior Implementation Class naming pattern for NAME-04

## Recommended Fields

- `auth_check_class_pattern` — Class pattern for RAP-04 authorization delegation check
- `service_binding_suffix_rules` — Naming rules for Service Definition and Service Binding (NAME-07)
- `obsolete_package` — Package where obsolete objects should be assigned (DOC-05)

## Optional Fields

- `naming_exceptions` — list of object names exempt from NAME-01 check
- `rule_suppressions` — rule IDs to suppress entirely for this project (e.g. DOC-03 if KT docs are tracked externally)

## Lazy Loading

config.md is the required entry point. Use `→ Read configs/naming.md for ...` to link additional files.
