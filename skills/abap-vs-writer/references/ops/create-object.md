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
