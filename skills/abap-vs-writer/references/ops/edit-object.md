# Operation: Edit ABAP Object

Edits an existing ABAP object's source code via the VS Code ADT cache, then
activates it. Uses `abap_activate_objects` as both syntax check and activation —
it returns `objectDiagnostics` on error without activating.

**Max activation attempts: 3.** If the object still fails after 3 fix→activate
cycles, stop and report all remaining diagnostics to the user.

---

## Step 1 — Find the cache file

Use the `abap-vs-reader` skill logic to locate the cache file for the object.

The cache path follows this pattern:
```
{cache_base}/.adt/{subdirectory}/{encoded_name}/{filename}
```

Read `abap-vs-reader` Phase 2 (Steps 2.3–2.6) for:
- object type → subdirectory mapping
- object name encoding rules
- auto-open retry loop via `open-abap.ps1` if the file is missing

**Editable files by object type:**

| Object type | File to edit | Notes |
|---|---|---|
| Class — definitions | `.aclass` | PUBLIC/PROTECTED/PRIVATE sections |
| Class — implementation | `*implementations.acinc` | Method bodies |
| Class — local types | `*definitions.acinc` | Local class/type declarations |
| Class — test classes | `*testclasses.acinc` | ABAP Unit tests |
| Interface | `.aint` | Full interface source |
| CDS View / Abstract Entity | `.asddls` | DDL source |
| Metadata Extension | `.asddlxex` | UI annotations |
| Behavior Definition | `.asbdef` | RAP behavior definition |
| Service Definition | `.assrvds` | `define service` source |

Never edit `.ap*`, `.$$$`, `.astec`, `.prefs`, `.project`, `.properties`, `.devck`.

---

## Step 2 — Edit the file

Use the `Edit` tool to apply the required changes to the cache file.

The VS Code ADT extension detects the file change and syncs it to the SAP system
automatically. No explicit save step is needed.

---

## Step 3 — Activate loop (max 3 attempts)

Repeat up to **3 times**:

### 3.a — Call `abap_activate_objects`

```
destination: {destination from config}
uris:        ["{filePath or URI from uri-patterns.md}"]
```

URI source priority:
1. `filePath` returned by `abap_creation-create_object` in the current session
2. Build from `references/uri-patterns.md`

### 3.b — On success (`"success": true, "objectDiagnostics": []`)

Report: "Activated successfully." Stop the loop.

### 3.c — On failure (`"success": false`)

1. Show the full `objectDiagnostics` array to the user (severity, shortText, longText)
2. Analyse the diagnostics and fix the source code using the `Edit` tool
3. Increment attempt counter and repeat from 3.a

**Common diagnostic causes and fixes:**

| Cause | Fix |
|---|---|
| Syntax error (missing period, keyword typo) | Fix in `.aclass` / `.acinc` |
| Unsaved changes | Edit tool already writes to disk — retry activate |
| Type/method not found | Check spelling, add missing definition |
| Dependency not activated | Activate the dependency first, then retry |

---

## Step 4 — After 3 failed attempts

Stop. Report:
- All remaining `objectDiagnostics` from the last attempt
- Which file was being edited (`{cache_file_path}`)
- Ask the user to review the issues manually in VS Code

---

## Combine with unit tests

If the user asked to "edit and test": after successful activation, follow
`references/ops/run-unit-tests.md` using the same URI.
