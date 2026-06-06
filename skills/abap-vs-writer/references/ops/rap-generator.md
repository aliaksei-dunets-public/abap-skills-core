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
destination:            {destination from config}
generatorId:            {same as Step 2}
packageName:            {same as Step 2}
transportRequestNumber: {"" for $TMP, or TR number}
content:                {JSON string of filled schema based on referenceContent}
referencedObjectType:   {same as Step 2}
referencedObjectName:   {same as Step 2}
```

**On success:** report `generatedObjects[]` list (object names + types).

**On failure:** report `validationMessages[]` — these contain specific field errors.
Fix the content JSON and retry.
