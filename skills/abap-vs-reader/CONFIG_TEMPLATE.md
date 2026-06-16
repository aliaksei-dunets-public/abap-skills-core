# Config Template: abap-vs-reader

Required fields for the project's config files. The skill is **virtual-URI
first**: Phase 1 (`abap:/repotree-v1/...`) handles all single-object reads.
Physical cache is the fallback.

---

## Required in `project-config.md`

| Field | Format | Description |
|---|---|---|
| `primary_namespace` | `(NS)` e.g. `(DEMO)` | Prepended to bare object names with no prefix. Asked from the user if missing. |

```markdown
primary_namespace: (DEMO)
```

---

## Required in `configs/system.md` — Phase 1 (virtual URI, primary)

Without these, Phase 1 cannot run and the skill drops to the slower fallback.

| Field | Format | Description |
|---|---|---|
| `system_id` | `<ID>` e.g. `ABC_001_USER_EN` | ADT system connection ID. Must match the segment after `/repotree-v1/`. |
| `virtual_root_segment` | Display segment | Top-level segment under `repotree-v1/<system_id>/`. Almost always `System Library` (use `Local Objects ($TMP)` for `$TMP`). Pass literal spaces and parens — do **not** pre-encode. |
| `virtual_top_package` | `(NS)PKG` | Display name of the top package, e.g. `(DEMO)PP`. |

### Optional Phase 1 hints

| Field | Format | Description |
|---|---|---|
| `virtual_default_subpackage_chain` | `(NS)A/(NS)B` | Default sub-package chain inserted when the user gives a bare name. Empty if objects sit directly under `virtual_top_package`. |
| `virtual_known_subpackages` | YAML map | Object-name pattern → sub-package chain. Lets the skill jump straight to the right URI without enumerating. |
| `virtual_type_label_overrides` | YAML map | Object-type → URI type-label overrides for custom types not covered by `references/object-types.md`. |

```markdown
system_id: ABC_001_USER_EN
label: ABC — Development (VSCode ADT)
virtual_root_segment: System Library
virtual_top_package: (DEMO)PP
virtual_default_subpackage_chain:
virtual_known_subpackages:
  '(DEMO)CL_UPLOAD_*': (DEMO)COCKPITS/(DEMO)UPLOAD_FILE
  '(DEMO)I_PRICING_*': (DEMO)PRICING
```

> Pass these segments to `read_file` literally (with spaces and parens). The
> `read_file` tool URL-encodes internally — pre-encoding produces ENOENT.

---

## Required in `configs/system.md` — Phase 2 (physical cache, fallback)

Used only when Phase 1 fails (ENOENT/empty), and for fuzzy lookup (Phase 3).

| Field | Format | Description |
|---|---|---|
| `cache_base` | Absolute path | ADT extension cache root containing the `.adt/` subdirectory tree. |
| `repotree_package_path` | URL-encoded path | URL-encoded package path used to render display links back to the user. Optional but recommended. |

```markdown
cache_base: c:/Users/YourUser/AppData/Roaming/Code/User/workspaceStorage/<hash>/SAPSE.adt-vscode/adtWorkspace/.metadata/.plugins/org.eclipse.core.resources.semantic/.cache/ABC_001_USER_EN
repotree_package_path: System%20Library/(DEMO)PKG/Source%20Library/(DEMO)PKG
```

### How to find `cache_base`

```
%APPDATA%\Code\User\workspaceStorage\<workspace-hash>\SAPSE.adt-vscode\adtWorkspace\.metadata\.plugins\org.eclipse.core.resources.semantic\.cache\<SYSTEM_ID>
```

Find the right `<workspace-hash>` by opening VS Code, connecting to the system
via the ADT extension, then matching `workspace.json` in
`%APPDATA%\Code\User\workspaceStorage`. The `<SYSTEM_ID>` inside the cache must
match the ADT system ID.

---

## Recommended

| Field | Format | Description |
|---|---|---|
| `label` | Free text | Human-readable system label, used in display output. |

---

## `configs/config.md` minimal content

```markdown
# ABAP VS Reader — Project Config

→ Read `configs/system.md` for ADT connection and system details.
```
