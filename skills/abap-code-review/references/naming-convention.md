# Naming Convention Rules (NAME)

This is a generic baseline. If the workspace provides an explicit naming overlay via `configs/config.md`, that rule set takes precedence over the examples here.

## Principles

- Names should reflect role and business meaning.
- Names should stay consistent within the object and its immediate collaborators.
- Abbreviations should only be used when their meaning is clear in context.

## Rules

| Rule ID | What to check | Severity |
|---------|--------------|----------|
| NAME-01 | Object name not starting with the project namespace prefix (`primary_namespace` from config) | WARNING |
| NAME-02 | DDIC objects (Domain, Data Element, Structure, Table Type, DB Table) not following project naming rules (`ddic_naming_rules` from config) | WARNING |
| NAME-03 | CDS/RAP objects (Interface View, Projection View, Base View, Draft table, TP view) not following project view naming rules (`cds_naming_rules` from config) | WARNING |
| NAME-04 | Behavior Implementation Class not following project BP class naming pattern (`bp_class_pattern` from config) | WARNING |
| NAME-05 | Local handler class not named `lhc_<Name>` or local saver class not named `lsc_<Name>` | INFO |
| NAME-06 | Method IMPORTING parameters not prefixed `I_`, EXPORTING `E_`, CHANGING `C_`, RETURNING `R_` — exception: RAP-generated parameter names must NOT be renamed | INFO |
| NAME-07 | Service Definition missing a semantic name, or Service Binding missing the protocol-type suffix (`service_binding_suffix_rules` from config) | WARNING |
| NAME-08 | Mixed variable naming styles within the same class body — only report when two identifiably different schemes are used side-by-side | INFO |

## What Not To Do

- Do not report a project-specific prefix rule as universal ABAP truth.
- Do not escalate naming issues above behavioral or contract defects.
- Do not treat a different but internally consistent local scheme as automatically wrong.
