# Config Template: abap-vs-writer

Documents what must be present in the project config for the `abap-vs-writer`
skill to function correctly.

---

## Required in `configs/system.md`

| Field | Format | Description |
|-------|--------|-------------|
| `destination` | string | ABAP system connection ID as shown in the ADT VSCode extension. Must match the value returned by `abap_list_destinations`. Example: `DEMO_001_EN`. |

Example:

```markdown
# ADT System Config

destination: DEMO_001_EN
```

---

## How to find your destination

Run the MCP tool `abap_list_destinations` with no parameters. The result lists
all registered destinations in brackets, e.g. `[DEMO_001_EN]`. Use
that value as `destination`.

---

## Optional in `configs/system.md`

| Field | Format | Description |
|-------|--------|-------------|
| `default_package` | string | Package used when no package is specified. Set to `$TMP` for local-only development. |
| `user` | string | SAP username (e.g. `DEMOUSER`). Used to construct `$TMP` URIs. If not set, the skill will ask the user when building a URI for `$TMP` objects. |
