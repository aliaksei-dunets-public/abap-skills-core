# Operation: Activate ABAP Objects

Activates one or more ABAP objects. All files must be saved in VS Code before
activating. When activating a single object after editing, use the **loop** below
(max 3 attempts with auto-fix). For bulk activation of already-correct objects,
use the single-call flow.

---

## Get the URI

URI source priority:
1. **`filePath`** returned by `abap_creation-create_object` in the current session — use directly
2. **Build from pattern** in `references/uri-patterns.md` using object name + type + package

---

## Single-call flow (bulk / already-correct objects)

`abap_activate_objects`:

```
uris: ["{uri1}", "{uri2}", ...]
```

- Maximum **15 URIs** per call
- For more than 15 objects: split into multiple calls

**Success:** `{"success": true, "objectDiagnostics": []}` — report "Activated successfully."

**Failure:** report the full `objectDiagnostics` array and switch to the loop below.

---

## Activate loop (single object, max 3 attempts)

Use this when activating after an edit or create+write operation.

Repeat up to **3 times**:

### A — Call `abap_activate_objects`

```
destination: {destination from config}
uris:        ["{uri}"]
```

### B — On success (`"success": true, "objectDiagnostics": []`)

Report: "Activated successfully." Stop the loop.

### C — On failure (`"success": false`)

1. Show the full `objectDiagnostics` array (severity, shortText, longText)
2. Fix the source in the cache file using the `Edit` tool
3. Increment attempt counter and repeat from A

**Common causes and fixes:**

| Cause | Fix |
|---|---|
| Syntax error (missing period, keyword typo) | Fix in `.aclass` / `.acinc` |
| Type/method not found | Add missing definition or fix spelling |
| Dependency not activated | Activate dependency first, then retry |

**After 3 failed attempts:** stop, report all remaining diagnostics, ask the
user to review manually in VS Code.

---

## Example

Activate class `ZCL_MY_CLASS` in `$TMP` (user `DEMOUSER`, dest `DEMO_001_EN`):

```
uris: ["abap:/repotree-v1/DEMO_001_EN/Local%20Objects%20%28%24TMP%29/DEMOUSER/Source%20Code%20Library/Classes/ZCL_MY_CLASS/zcl_my_class.clas.abap"]
```
