# Config Template: abap-vs-reader

Documents what must be present in each config file for the `abap-vs-reader` skill to
function correctly.

---

## Required in `project-config.md`

| Field | Format | Description |
|---|---|---|
| `primary_namespace` | `(NS)` e.g. `(DEMO)` | Default namespace prepended to bare object names that have no prefix. Used in Step 1 of the skill when the user provides a name like `CL_MY_CLASS` without a namespace. |

Example:

```markdown
# Project Config

primary_namespace: (DEMO)
```

---

## Required in `configs/system.md`

| Field | Format | Description |
|---|---|---|
| `system_id` | `<ID>` e.g. `ABC_001_DEMOUSER_EN` | SAP system connection ID as shown in the ADT VSCode extension. Must match the segment immediately after `/repotree-v1/` in ADT paths. |
| `cache_base` | Absolute path | Full path to the ADT VSCode extension cache root for this system. This is the directory that contains the `.adt/` subdirectory tree. |
| `repotree_package_path` | URL-encoded path | The package path segment used in repotree URIs, e.g. `System%20Library/(DEMO)PKG/Source%20Library/(DEMO)PKG`. Used when constructing full repotree URIs for display or linking. |

Example:

```markdown
# ADT System Config — DEMO

system_id: ABC_001_USER_EN
label: ABC — Development (VSCode ADT)
cache_base: c:/Users/YourUser/AppData/Roaming/Code/User/workspaceStorage/<hash>/SAPSE.adt-vscode/adtWorkspace/.metadata/.plugins/org.eclipse.core.resources.semantic/.cache/ABC_001_USER_EN
repotree_package_path: System%20Library/(DEMO)PKG/Source%20Library/(DEMO)PKG
```

---

## Required in `configs/system.md` for the Phase 0.5 fast path

These fields enable the **virtual `abap:` URI** route (Phase 0.5 of the skill).
Without them the agent falls back to the slower physical-cache path.

| Field | Format | Description |
|---|---|---|
| `virtual_root_segment` | Display segment | Top-level segment under `repotree-v1/<system_id>/`. Almost always `System Library` (use `Local Objects ($TMP)` for `$TMP` development). Pass **literal** spaces and parentheses — do not pre-encode. |
| `virtual_top_package` | `(NS)PKG` | Display name of the top package, e.g. `(DEMO)PP`. Combined with `virtual_root_segment` to form the URI prefix. |
| `virtual_default_subpackage_chain` | `(NS)A/(NS)B` | Optional. Default sub-package chain inserted between the top package and the type-label folder when the user provides a bare object name. Leave empty if all relevant objects sit directly under `virtual_top_package`. |
| `virtual_known_subpackages` | YAML map | Optional. Map of object-name patterns → sub-package chain. Lets the skill jump directly to the right URI for well-known projects without enumerating the package tree. |

Example:

```markdown
# Phase 0.5 fast-path config

virtual_root_segment: System Library
virtual_top_package: (DEMO)PP
virtual_default_subpackage_chain: 
virtual_known_subpackages:
  '(DEMO)CL_UPLOAD_*': (DEMO)COCKPITS/(DEMO)UPLOAD_FILE
  '(DEMO)I_PRICING_*': (DEMO)PRICING
```

> **Reading rule.** The agent must pass these segments to `read_file` *literally*
> (with spaces and parentheses), not URL-encoded. The `read_file` tool URL-encodes
> them internally when it forwards the request to the ADT virtual filesystem
> provider. Pre-encoding produces ENOENT.

---

## Object-type label mapping for the virtual URI

The skill's Step 2.3.5 documents the canonical type-label segments to use in
virtual URIs. Projects that introduce custom or extension object types should
add overrides here:

| Field | Format | Description |
|---|---|---|
| `virtual_type_label_overrides` | YAML map | Optional. Object-type → URI segment overrides for non-standard or extension types not covered by Step 2.3.5. |

Example:

```markdown
virtual_type_label_overrides:
  Z_CUSTOM_TYPE: Source Code Library/Custom Objects
```

---

## Recommended in `configs/system.md`

| Field | Format | Description |
|---|---|---|
| `label` | Free text | Human-readable label for the system (e.g. `ABC — Development (VSCode ADT)`). Used in display output and log messages to identify which system is being accessed. |

---

## How to find `cache_base`

The ADT VSCode extension stores its semantic cache under:

```
%APPDATA%\Code\User\workspaceStorage\<workspace-hash>\SAPSE.adt-vscode\adtWorkspace\.metadata\.plugins\org.eclipse.core.resources.semantic\.cache\<SYSTEM_ID>
```

To find the correct `<workspace-hash>`, open VS Code, connect to your SAP system via
the ADT extension, then look in `%APPDATA%\Code\User\workspaceStorage` for the folder
whose `workspace.json` refers to your project. The `<SYSTEM_ID>` directory inside the
cache will match the system ID shown in the ADT extension.

---

## config.md minimal content

The `configs/config.md` file in the project must at minimum reference `system.md`:

```markdown
# ABAP VS Reader — Project Config

→ Read `configs/system.md` for ADT connection and system details.
```
