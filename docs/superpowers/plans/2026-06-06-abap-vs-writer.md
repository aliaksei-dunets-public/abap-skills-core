# abap-vs-writer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the `abap-vs-writer` skill in `abap-skills-core` that gives an AI agent complete, zero-discovery instructions for all ABAP ADT MCP write operations.

**Architecture:** Dispatch-based skill — `SKILL.md` reads config and routes to one or more `references/ops/*.md` files based on signals in the user request. All object type schemas and URI patterns are pre-baked into reference files so no runtime `get_object_type_details` calls are needed.

**Tech Stack:** Markdown skill files following `abap-skills-core` conventions. No scripts (all MCP calls are direct).

---

## File Map

| File | Responsibility |
|------|---------------|
| `skills/abap-vs-writer/SKILL.md` | Entry point: config resolution + dispatch table |
| `skills/abap-vs-writer/CONFIG_TEMPLATE.md` | Documents required config fields |
| `skills/abap-vs-writer/references/object-types.md` | All 14 objectType schemas — fields, lengths, enum values |
| `skills/abap-vs-writer/references/uri-patterns.md` | URI templates for activate/test, all object types |
| `skills/abap-vs-writer/references/ops/create-object.md` | validate → create workflow |
| `skills/abap-vs-writer/references/ops/activate.md` | activate_objects workflow |
| `skills/abap-vs-writer/references/ops/run-unit-tests.md` | run_unit_tests workflow |
| `skills/abap-vs-writer/references/ops/transport.md` | transport-get + transport-create rules |
| `skills/abap-vs-writer/references/ops/rap-generator.md` | list → schema → generate workflow |
| `skills/abap-vs-writer/references/ops/atc-check.md` | ATC check workflow + fallback |

All paths relative to `c:\Users\C5227045\Documents\Atlas PP\abap-skills-core\`.

---

## Task 1: SKILL.md — entry point and dispatch

**Files:**
- Create: `skills/abap-vs-writer/SKILL.md`

- [ ] **Step 1: Create SKILL.md**

```markdown
---
name: abap-vs-writer
description: >
  Use this skill whenever the user wants to create, activate, run unit tests on,
  manage transports for, or generate RAP services for ABAP objects via the ADT MCP
  server. Trigger on: "create class", "create interface", "create CDS", "create BDEF",
  "create service", "activate", "run tests", "unit tests", "transport", "TR",
  "RAP generator", "OData service", "ATC check", "code check", or equivalent in any
  language. Also trigger when the user provides an object name and asks to create,
  activate, or test it.
---

# abap-vs-writer — Core Skill

Executes write-side ABAP ADT operations via the MCP server: creating objects,
activating them, running unit tests, managing transport requests, and generating
full RAP services.

All object schemas and URI patterns are pre-loaded in reference files — no runtime
discovery calls needed.

---

## Phase 0 — Resolve Config

Read `configs/system.md` (loaded via the project config chain).

Extract:
- `destination` — ABAP system connection ID (e.g. `ISD_001_C5227045_EN`)

If the field is missing or `configs/system.md` does not exist: stop, tell the user
which field is absent, and refer them to `CONFIG_TEMPLATE.md`.

Use `destination` in every subsequent MCP call.

---

## Phase 1 — Dispatch

Load only the reference files that match the current task. Do not load all files.

| Signal in user request | Reference files to load |
|------------------------|------------------------|
| create / новый / class / interface / CDS / BDEF / service binding / service definition / interface / domain / data element | `references/ops/create-object.md` + `references/object-types.md` |
| activate / активировать / активация | `references/ops/activate.md` + `references/uri-patterns.md` |
| unit test / run tests / тесты / запустить тесты | `references/ops/run-unit-tests.md` + `references/uri-patterns.md` |
| transport / TR / транспорт / задание переноса | `references/ops/transport.md` |
| RAP / generator / генератор / OData service / x-ui-service / webapi-service | `references/ops/rap-generator.md` |
| ATC / code check / статический анализ / ABAP Test Cockpit | `references/ops/atc-check.md` |

When the task combines operations (e.g. "create and activate"), load all matching
reference files.

---

## Phase 2 — Execute

Follow the instructions in the loaded reference file(s). Use `destination` from
Phase 0 in every MCP tool call. Do not call `abap_creation-get_object_type_details`
at runtime — all schemas are in `references/object-types.md`.
```

- [ ] **Step 2: Verify file exists and structure is correct**

Read `skills/abap-vs-writer/SKILL.md` and confirm:
- frontmatter with `name` and `description` is present
- Phase 0, Phase 1, Phase 2 sections exist
- dispatch table has 6 rows

- [ ] **Step 3: Commit**

```bash
cd "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core"
git add skills/abap-vs-writer/SKILL.md
git commit -m "feat(abap-vs-writer): add SKILL.md entry point with dispatch table"
```

---

## Task 2: CONFIG_TEMPLATE.md

**Files:**
- Create: `skills/abap-vs-writer/CONFIG_TEMPLATE.md`

- [ ] **Step 1: Create CONFIG_TEMPLATE.md**

```markdown
# Config Template: abap-vs-writer

Documents what must be present in the project config for the `abap-vs-writer`
skill to function correctly.

---

## Required in `configs/system.md`

| Field | Format | Description |
|-------|--------|-------------|
| `destination` | string | ABAP system connection ID as shown in the ADT VSCode extension. Must match the value returned by `abap_list_destinations`. Example: `ISD_001_C5227045_EN`. |

Example:

```markdown
# ADT System Config

destination: ISD_001_C5227045_EN
```

---

## How to find your destination

Run the MCP tool `abap_list_destinations` with no parameters. The result lists
all registered destinations in brackets, e.g. `[ISD_001_C5227045_EN]`. Use
that value as `destination`.

---

## Optional in `configs/system.md`

| Field | Format | Description |
|-------|--------|-------------|
| `default_package` | string | Package used when no package is specified. Set to `$TMP` for local-only development. |
| `user` | string | SAP username (e.g. `C5227045`). Used to construct `$TMP` URIs. If not set, the skill will ask the user when building a URI for `$TMP` objects. |
```

- [ ] **Step 2: Commit**

```bash
cd "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core"
git add skills/abap-vs-writer/CONFIG_TEMPLATE.md
git commit -m "feat(abap-vs-writer): add CONFIG_TEMPLATE.md"
```

---

## Task 3: references/object-types.md

**Files:**
- Create: `skills/abap-vs-writer/references/object-types.md`

- [ ] **Step 1: Create object-types.md**

```markdown
# ABAP Object Types — Schema Reference

Use this file to build `objectContent` for `abap_creation-run_validation` and
`abap_creation-create_object`. Do NOT call `abap_creation-get_object_type_details`
at runtime — all schemas are here.

## Critical Rule

`objectContent` MUST be a JSON-encoded string (not a raw object):

```
objectContent: "{\"packageName\":\"$TMP\",\"name\":\"ZCL_MY_CLASS\",\"description\":\"My class\"}"
```

Passing individual fields (name=, description=) fails with "Enter valid object properties."

---

## Object Type Table

| Display Name | objectType | name maxLength | Required fields | Optional fields |
|---|---|---|---|---|
| ABAP Class | `CLAS/OC` | 30 | packageName, name, description | superclass, interfaces |
| ABAP Interface | `INTF/OI` | 30 | packageName, name, description | interfaces |
| Behavior Definition | `BDEF/BDO` | 30 | packageName, rootEntity, name, description | implementationType |
| Access Control | `DCLS/DL` | 30 | packageName, name, description | protectedEntity |
| Data Definition | `DDLS/DF` | 30 | packageName, name, description | referencedObject |
| Metadata Extension | `DDLX/EX` | **40** | packageName, name, description | extendedEntity |
| CDS Aspect | `DRAS/RAS` | 30 | packageName, name, description | — |
| CDS Type | `DRTY/STY` | 30 | packageName, name, description | — |
| Service Binding | `SRVB/SVB` | 30 | packageName, name, description, serviceDefinition | bindingType |
| Service Definition | `SRVD/SRV` | 30 | packageName, name, description | sourceType, referencedObject |
| Change Document Object | `CHDO/CHD` | **15** | packageName, name, description | — |
| SAP Object Node Type | `NONT/NOT` | 30 | packageName, name, description, sapObjectType | isRootNode |
| Number Range Object | `NROB/NRO` | **10** | packageName, name, description | — |
| SAP Object Type | `RONT/ROT` | 30 | packageName, name, description | typeCategory |

**Non-standard name lengths (exceptions to default 30):**
- `DDLX/EX` → max **40**
- `CHDO/CHD` → max **15**
- `NROB/NRO` → max **10**

---

## Optional Field Enum Values

### BDEF/BDO — implementationType
`Managed` | `Unmanaged` | `Projection` | `Abstract` | `Interface`

### SRVB/SVB — bindingType
`OData V2 - UI` | `OData V4 - UI`

### SRVD/SRV — sourceType
`S` (Service Definition) | `X` (External) | *(empty string for default)*

### RONT/ROT — typeCategory
`Business Object` | `Technical Object` | `Analytical Object` |
`Configuration Object` | `Dependent Object` | `Hierarchy Object`

---

## objectContent Examples

**ABAP Class in $TMP:**
```json
{"packageName":"$TMP","name":"ZCL_MY_CLASS","description":"My class description"}
```

**ABAP Interface in $TMP:**
```json
{"packageName":"$TMP","name":"ZIF_MY_INTERFACE","description":"My interface"}
```

**CDS Data Definition in $TMP:**
```json
{"packageName":"$TMP","name":"ZI_MY_VIEW","description":"My CDS view"}
```

**Behavior Definition in $TMP:**
```json
{"packageName":"$TMP","name":"ZI_MY_VIEW","description":"Behavior for ZI_MY_VIEW","rootEntity":"ZI_MY_VIEW","implementationType":"Managed"}
```

**Service Binding in $TMP:**
```json
{"packageName":"$TMP","name":"ZUI_MY_SRV_O4","description":"OData V4 UI Service","serviceDefinition":"ZSD_MY_SRV","bindingType":"OData V4 - UI"}
```
```

- [ ] **Step 2: Commit**

```bash
cd "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core"
git add skills/abap-vs-writer/references/object-types.md
git commit -m "feat(abap-vs-writer): add object-types.md with all 14 schemas"
```

---

## Task 4: references/uri-patterns.md

**Files:**
- Create: `skills/abap-vs-writer/references/uri-patterns.md`

- [ ] **Step 1: Create uri-patterns.md**

```markdown
# URI Patterns for ABAP ADT Objects

Use these patterns to build URIs for `abap_activate_objects` and
`abap_run_unit_tests`. The preferred source for a URI is always the `filePath`
field returned by `abap_creation-create_object` — use these patterns only when
`filePath` is not available.

## Placeholders

| Placeholder | Value |
|---|---|
| `{DEST}` | destination from config, e.g. `ISD_001_C5227045_EN` |
| `{USER}` | SAP username uppercase, e.g. `C5227045` |
| `{NAME_UPPER}` | Object name uppercase, e.g. `ZCL_MY_CLASS` |
| `{name_lower}` | Object name lowercase, e.g. `zcl_my_class` |
| `{PKG_ENC}` | URL-encoded package path segment (see Package Objects section) |

---

## $TMP Local Objects

Base: `abap:/repotree-v1/{DEST}/Local%20Objects%20%28%24TMP%29/{USER}/Source%20Code%20Library`

| Object type | objectType | Append to base | File extension |
|---|---|---|---|
| Class | CLAS/OC | `/Classes/{NAME_UPPER}/{name_lower}.clas.abap` | `.clas.abap` |
| Interface | INTF/OI | `/Interfaces/{NAME_UPPER}/{name_lower}.intf.abap` | `.intf.abap` |
| Data Definition | DDLS/DF | `/Data%20Definitions/{NAME_UPPER}/{name_lower}.ddls.asddls` | `.ddls.asddls` |
| Metadata Extension | DDLX/EX | `/Metadata%20Extensions/{NAME_UPPER}/{name_lower}.ddlx.asddlxex` | `.ddlx.asddlxex` |
| Behavior Definition | BDEF/BDO | `/Behavior%20Definitions/{NAME_UPPER}/{name_lower}.bdef.asbdef` | `.bdef.asbdef` |
| Service Definition | SRVD/SRV | `/Service%20Definitions/{NAME_UPPER}/{name_lower}.srvd.assrvds` | `.srvd.assrvds` |
| Service Binding | SRVB/SVB | `/Service%20Bindings/{NAME_UPPER}/{name_lower}.srvb.srvbsvb` | `.srvb.srvbsvb` |
| Access Control | DCLS/DL | `/Access%20Controls/{NAME_UPPER}/{name_lower}.dcls.asdcls` | `.dcls.asdcls` |

### $TMP Class — Full Example

```
abap:/repotree-v1/ISD_001_C5227045_EN/Local%20Objects%20%28%24TMP%29/C5227045/Source%20Code%20Library/Classes/ZCL_MY_CLASS/zcl_my_class.clas.abap
```

### $TMP Interface — Full Example

```
abap:/repotree-v1/ISD_001_C5227045_EN/Local%20Objects%20%28%24TMP%29/C5227045/Source%20Code%20Library/Interfaces/ZIF_MY_INTERFACE/zif_my_interface.intf.abap
```

---

## Package-Based Objects

Base: `abap:/repotree-v1/{DEST}/System%20Library/{PKG_ENC}/Source%20Library/{PKG_ENC}`

`{PKG_ENC}` is the URL-encoded package name. Example for package `ZMYPKG`:
`ZMYPKG` → `ZMYPKG` (no encoding needed for alphanumeric names).

For namespace packages like `(HEC4)PP`:
`(HEC4)PP` → `%28HEC4%29PP`

The object type folders and file extensions are the same as for $TMP objects above.

---

## Activation Limit

`abap_activate_objects` accepts a maximum of **15 URIs** per call. If activating
more than 15 objects, split into multiple calls.
```

- [ ] **Step 2: Commit**

```bash
cd "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core"
git add skills/abap-vs-writer/references/uri-patterns.md
git commit -m "feat(abap-vs-writer): add uri-patterns.md"
```

---

## Task 5: references/ops/create-object.md

**Files:**
- Create: `skills/abap-vs-writer/references/ops/create-object.md`

- [ ] **Step 1: Create create-object.md**

```markdown
# Operation: Create ABAP Object

Creates any ABAP object via the ADT MCP server in 3 steps. No discovery calls —
all schemas are in `references/object-types.md`.

---

## Pre-flight: Package check

- If package is `$TMP`: set `transportRequestNumber = ""`, skip transport step.
- If package is NOT `$TMP`: read `references/ops/transport.md`, get TR from user
  before proceeding.

---

## Step 1 — Validate

Call `abap_creation-run_validation`:

```
destination:   {destination from config}
objectType:    {objectType from object-types.md, e.g. "CLAS/OC"}
objectContent: "{\"packageName\":\"{PKG}\",\"name\":\"{NAME_UPPER}\",\"description\":\"{description}\"}"
```

**objectContent rules:**
- Must be a JSON-encoded **string** — not a raw object
- `name` should be uppercase
- Include only fields listed as Required + any Optional fields the user specified
- Do NOT include fields not present in the object-types.md table for this type

**On validation failure:** show the error message, stop. Do not proceed to Step 2.

**On success:** proceed to Step 2.

---

## Step 2 — Create

Call `abap_creation-create_object`:

```
destination:            {destination from config}
objectType:             {same as Step 1}
objectContent:          {same as Step 1}
transportRequestNumber: {empty string "" for $TMP, or TR number from transport step}
```

**On failure:** show the error message, stop.

**On success:**
- Save `filePath` from the response — this is the canonical URI for this object
- Proceed to Step 3

---

## Step 3 — Report

Tell the user:
- Object was created successfully
- The `filePath` value (so they can open it in VS Code)
- Suggest next steps: open in VS Code to edit source code, then activate

Example output:
```
Created: ZCL_MY_CLASS
Path: abap:/repotree-v1/ISD_001_C5227045_EN/Local%20Objects%20%28%24TMP%29/C5227045/Source%20Code%20Library/Classes/ZCL_MY_CLASS/zcl_my_class.clas.abap

Next: open in VS Code, edit source, then activate.
```

---

## Combine with Activate

If the user asked to "create and activate" in one step:
1. Complete all 3 steps above
2. Then follow `references/ops/activate.md` using the `filePath` from Step 2
```

- [ ] **Step 2: Commit**

```bash
cd "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core"
git add skills/abap-vs-writer/references/ops/create-object.md
git commit -m "feat(abap-vs-writer): add ops/create-object.md"
```

---

## Task 6: references/ops/activate.md

**Files:**
- Create: `skills/abap-vs-writer/references/ops/activate.md`

- [ ] **Step 1: Create activate.md**

```markdown
# Operation: Activate ABAP Objects

Activates one or more ABAP objects. All files must be saved in VS Code before
activating.

---

## Get the URI

URI source priority:
1. **`filePath`** returned by `abap_creation-create_object` in the current session — use directly
2. **Build from pattern** in `references/uri-patterns.md` using object name + type + package

---

## Call

`abap_activate_objects`:

```
uris: ["{uri1}", "{uri2}", ...]
```

- Maximum **15 URIs** per call
- For more than 15 objects: split into multiple calls

---

## Response Handling

**Success:**
```json
{"success": true, "objectDiagnostics": []}
```
Report: "Activated successfully."

**Failure:**
```json
{"success": false, "objectDiagnostics": [{"severity": "E", "shortText": "..."}]}
```
Report the full `objectDiagnostics` array. Common causes:
- Syntax error in the source — user must fix in VS Code and retry
- Unsaved changes — user must save the file in VS Code first
- Dependency not activated — activate the dependency first

---

## Example

Activate class `ZCL_MY_CLASS` in `$TMP` (user `C5227045`, dest `ISD_001_C5227045_EN`):

```
uris: ["abap:/repotree-v1/ISD_001_C5227045_EN/Local%20Objects%20%28%24TMP%29/C5227045/Source%20Code%20Library/Classes/ZCL_MY_CLASS/zcl_my_class.clas.abap"]
```
```

- [ ] **Step 2: Commit**

```bash
cd "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core"
git add skills/abap-vs-writer/references/ops/activate.md
git commit -m "feat(abap-vs-writer): add ops/activate.md"
```

---

## Task 7: references/ops/run-unit-tests.md

**Files:**
- Create: `skills/abap-vs-writer/references/ops/run-unit-tests.md`

- [ ] **Step 1: Create run-unit-tests.md**

```markdown
# Operation: Run ABAP Unit Tests

Runs ABAP Unit Tests for one or more objects. The tool auto-discovers the test
class include — always pass the main `.clas.abap` URI, not the testclass file.

---

## Get the URI

Same priority as activate: use `filePath` from create response, or build from
`references/uri-patterns.md`.

Always use the **main class URI** ending in `.clas.abap` — the tool finds the
`testclasses.acinc` automatically.

---

## Call

`abap_run_unit_tests`:

```
uris: ["{uri_to_main_clas_abap}"]
```

---

## Response Handling

**Tests pass:** output contains test method names with status PASS. Report summary.

**Tests fail:** output contains failure details (method name, assertion message,
expected vs actual). Report the full output verbatim — do not summarise failures.

**No tests found:** output is "No tests found" or similar. Inform the user that
the class has no test class include yet.

---

## Example

Run tests for `ZCL_MY_CLASS` in `$TMP`:

```
uris: ["abap:/repotree-v1/ISD_001_C5227045_EN/Local%20Objects%20%28%24TMP%29/C5227045/Source%20Code%20Library/Classes/ZCL_MY_CLASS/zcl_my_class.clas.abap"]
```
```

- [ ] **Step 2: Commit**

```bash
cd "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core"
git add skills/abap-vs-writer/references/ops/run-unit-tests.md
git commit -m "feat(abap-vs-writer): add ops/run-unit-tests.md"
```

---

## Task 8: references/ops/transport.md

**Files:**
- Create: `skills/abap-vs-writer/references/ops/transport.md`

- [ ] **Step 1: Create transport.md**

```markdown
# Operation: Transport Requests

Manage transport requests for ABAP objects in non-local packages.

**$TMP rule:** Objects in `$TMP` never need a transport. Skip this entire file
and use `transportRequestNumber = ""`.

---

## Get existing TRs

Before creating or modifying any non-$TMP object, call `abap_transport-get`:

```
destination:        {destination from config}
objectName:         {object name uppercase, e.g. "ZCL_MY_CLASS"}
objectType:         {objectType, e.g. "CLAS/OC"}
developmentPackage: {package name, e.g. "ZMYPKG"}
isCreation:         true   (for new objects) | false (for modifications)
```

**Show the full list of returned TRs to the user.** Wait for explicit selection.
Never auto-select a TR number.

If `isRecordingRequired` is `false` in the response, transport is optional —
inform the user and ask whether to assign one.

---

## Create a new TR

Only call `abap_transport-create` if the user explicitly asks to create a new
transport request:

```
destination:          {destination from config}
objectName:           {object name uppercase}
objectType:           {objectType}
developmentPackage:   {package name}
transportDescription: {short description, max 60 chars, like a commit message}
isCreation:           true | false
```

Report the new TR number to the user. Then use it as `transportRequestNumber`
in `create_object` or `create_object`.

---

## TR for RAP Generator

When generating RAP objects in a non-$TMP package, call `abap_transport-get`
with:
```
objectType:         "DEVC/K"
objectName:         {package name}
developmentPackage: {package name}
isCreation:         true
```

---

## Safety Rules

1. Never call `abap_transport-create` without user request
2. Never auto-select from the TR list — always wait for user choice
3. Never skip transport for non-$TMP packages unless `isRecordingRequired` is `false`
   and the user confirms they want to proceed without a TR
```

- [ ] **Step 2: Commit**

```bash
cd "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core"
git add skills/abap-vs-writer/references/ops/transport.md
git commit -m "feat(abap-vs-writer): add ops/transport.md"
```

---

## Task 9: references/ops/rap-generator.md

**Files:**
- Create: `skills/abap-vs-writer/references/ops/rap-generator.md`

- [ ] **Step 1: Create rap-generator.md**

```markdown
# Operation: RAP Generator

Generates a complete RAP OData service (CDS views, BDEF, service definition,
service binding) in 3 steps.

---

## Known Generators on ISD_001_C5227045_EN

| Title | generatorId | referencedObjectTypes | Notes |
|---|---|---|---|
| OData UI Service | `ui-service` | TABL;BDEF;DDLS | **NOT available** — returns "Generator does not exist" |
| OData Web API Service | `webapi-service` | TABL | Available |
| OData UI Service from Scratch | `x-ui-service` | *(none)* | Available — recommended for new services |

Use `x-ui-service` for a new UI service with no existing table reference.
Use `webapi-service` for a Web API service based on an existing table.

---

## Step 1 — List generators (optional)

Call `abap_generators-list_generators` if you need to confirm available generators:

```
destination: {destination from config}
```

Show the result to the user if they are unsure which generator to use.

---

## Step 2 — Get schema

Call `abap_generators-get_schema`:

```
destination:          {destination from config}
generatorId:          {e.g. "x-ui-service"}
packageName:          {package, e.g. "$TMP"}
referencedObjectType: {e.g. "TABL" for webapi-service, "" for x-ui-service}
referencedObjectName: {e.g. "ZMYTABLE" for webapi-service, "" for x-ui-service}
```

From the response:
- `referenceContent` contains a pre-populated template — use it as the base for `content`
- `referenceContent.sessionId` MUST be passed as `sessionId` in the content JSON

**Key content fields for x-ui-service:**

| Field path | Required | Notes |
|---|---|---|
| `metadata.package` | yes | Package name |
| `sessionId` | yes | From referenceContent.sessionId |
| `serviceConfiguration.serviceNaming.projectName` | yes | Max 24 chars |
| `serviceConfiguration.applicationType` | no | `readOnly` \| `withDraft` (default) \| `withoutDraft` |
| `serviceConfiguration.objectsNaming.prefix` | no | Max 3 chars |
| `serviceConfiguration.objectsNaming.suffix` | no | Max 3 chars |
| `businessEntities[].entityName` | yes per entity | Max 24 chars |
| `businessEntities[].compositionCardinality` | yes per entity | `toOne` \| `toMany` \| `none` |

Ask the user for: `projectName`, entity names + cardinalities, and `applicationType`
before building the content JSON.

---

## Step 3 — Generate

For non-$TMP packages: call `abap_transport-get` with `objectType="DEVC/K"` first
and wait for user TR selection.

Call `abap_generators-generate_objects`:

```
destination:          {destination from config}
generatorId:          {same as Step 2}
packageName:          {same as Step 2}
transportRequestNumber: {"" for $TMP, or TR number}
content:              {JSON string of filled schema based on referenceContent}
referencedObjectType: {same as Step 2}
referencedObjectName: {same as Step 2}
```

**On success:** report `generatedObjects[]` list (object names + types).

**On failure:** report `validationMessages[]` — these contain specific field errors.
Fix the content JSON and retry.
```

- [ ] **Step 2: Commit**

```bash
cd "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core"
git add skills/abap-vs-writer/references/ops/rap-generator.md
git commit -m "feat(abap-vs-writer): add ops/rap-generator.md"
```

---

## Task 10: references/ops/atc-check.md

**Files:**
- Create: `skills/abap-vs-writer/references/ops/atc-check.md`

- [ ] **Step 1: Create atc-check.md**

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
cd "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core"
git add skills/abap-vs-writer/references/ops/atc-check.md
git commit -m "feat(abap-vs-writer): add ops/atc-check.md"
```

---

## Task 11: Final verification

- [ ] **Step 1: Verify complete file structure**

Run:
```bash
find "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core/skills/abap-vs-writer" -type f | sort
```

Expected output (10 files):
```
.../skills/abap-vs-writer/CONFIG_TEMPLATE.md
.../skills/abap-vs-writer/SKILL.md
.../skills/abap-vs-writer/references/object-types.md
.../skills/abap-vs-writer/references/ops/activate.md
.../skills/abap-vs-writer/references/ops/atc-check.md
.../skills/abap-vs-writer/references/ops/create-object.md
.../skills/abap-vs-writer/references/ops/rap-generator.md
.../skills/abap-vs-writer/references/ops/run-unit-tests.md
.../skills/abap-vs-writer/references/ops/transport.md
.../skills/abap-vs-writer/references/uri-patterns.md
```

- [ ] **Step 2: Check dispatch table covers all ops files**

Confirm `SKILL.md` dispatch table has a row for each ops file:
- create-object.md ← "create / class / interface / CDS / BDEF / service"
- activate.md ← "activate"
- run-unit-tests.md ← "unit test / run tests"
- transport.md ← "transport / TR"
- rap-generator.md ← "RAP / generator"
- atc-check.md ← "ATC / code check"

- [ ] **Step 3: Final commit**

```bash
cd "c:/Users/C5227045/Documents/Atlas PP/abap-skills-core"
git log --oneline -12
```

Confirm 10 commits from Tasks 1–10 are present.
