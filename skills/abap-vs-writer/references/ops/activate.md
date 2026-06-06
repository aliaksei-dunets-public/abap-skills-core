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

Activate class `ZCL_MY_CLASS` in `$TMP` (user `DEMOUSER`, dest `DEMO_001_EN`):

```
uris: ["abap:/repotree-v1/DEMO_001_EN/Local%20Objects%20%28%24TMP%29/DEMOUSER/Source%20Code%20Library/Classes/ZCL_MY_CLASS/zcl_my_class.clas.abap"]
```
