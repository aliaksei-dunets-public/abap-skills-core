# abap-wiki-doc-creator — Config Template

Documents what must be present in each config file for the `abap-wiki-doc-creator` skill to function correctly.

---

## Required in `project-config.md`

These fields are read from the shared project config file.

| Field | Format | Description |
|---|---|---|
| `primary_namespace` | `(NS)` e.g. `(HEC4)` | Default namespace prepended to bare object names with no prefix. |

---

## Required in `configs/config.md`

| Field | Format | Description |
|---|---|---|
| `output_path` | Relative path | Where to save wiki files. Default: `docs/wiki`. Override if the project uses a different docs structure. |

Example:
```markdown
# abap-wiki-doc-creator — Project Config

output_path: docs/wiki

→ Read `configs/system.md` for ADT connection and source-reader details.
```

---

## Optional in `configs/config.md`

| Field | Format | Description |
|---|---|---|
| `default_feature_description` | Free text | Boilerplate text prepended to the Business Context section when the user provides no additional instructions. |
| `jira_project_key` | String e.g. `ATLAS` | Jira project key used in the Process Flow section to format ticket links. |

---

## Lazy Loading

`configs/config.md` is the required entry point. Use `→ Read configs/system.md for ...` to link the ADT system config needed by `abap-vs-reader`.
