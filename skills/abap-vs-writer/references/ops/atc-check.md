# Operation: ATC Check

Runs ABAP Test Cockpit (ATC) static code checks on ABAP objects.

---

## MCP Availability Check

ATC checks may or may not be exposed by the ADT MCP server. Before proceeding,
call `abap_list_destinations` and check whether any `abap_atc_*` tools are
listed in the available tools.

**If ATC tools are available:** use the tool with the object URI (same format as
`abap_activate_objects`). Report all findings with severity, message, and location.

**If ATC tools are NOT available:** inform the user:

> "ATC checks are not exposed by the ADT MCP server on this system. To run ATC
> checks, open the object in VS Code and use the SAP ADT extension's 'Run ATC
> Check' command (right-click the file in the ABAP Explorer, or use the command
> palette: 'ABAP: Run ATC Check')."

---

## URI Format

Same format as `abap_activate_objects`. Use `filePath` from create response or
build from `references/uri-patterns.md`.
