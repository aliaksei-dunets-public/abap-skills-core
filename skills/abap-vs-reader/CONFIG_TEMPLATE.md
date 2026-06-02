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
| `system_id` | `<ID>` e.g. `ABC_001_C5227045_EN` | SAP system connection ID as shown in the ADT VSCode extension. Must match the segment immediately after `/repotree-v1/` in ADT paths. |
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
