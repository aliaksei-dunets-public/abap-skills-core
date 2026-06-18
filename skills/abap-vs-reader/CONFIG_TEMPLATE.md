# Config Template: abap-vs-reader

## `project-config.md`

| Field | Format | Description |
|---|---|---|
| `primary_namespace` | `(NS)` e.g. `(DEMO)` | Prepended to bare object names with no namespace prefix. |

## `configs/system.md`

| Field | Required | Description |
|---|---|---|
| `system_id` | yes | ADT system connection ID. Must match the segment after `/repotree-v1/`. |
| `virtual_root_segment` | yes | Top-level segment under `repotree-v1/<system_id>/`. Almost always `System Library`. |
| `virtual_top_package` | yes | Display name of the top package, e.g. `(DEMO)PP`. |
| `virtual_default_subpackage_chain` | no | Default sub-package chain for bare names, e.g. `(DEMO)A/(DEMO)B`. Empty if objects sit directly under `virtual_top_package`. |
| `virtual_known_subpackages` | no | YAML map of object-name pattern → sub-package chain. |

```markdown
system_id: ABC_001_USER_EN
virtual_root_segment: System Library
virtual_top_package: (DEMO)PP
virtual_default_subpackage_chain:
virtual_known_subpackages:
  '(DEMO)CL_UPLOAD_*': (DEMO)COCKPITS/(DEMO)UPLOAD_FILE
  '(DEMO)I_PRICING_*': (DEMO)PRICING
```
