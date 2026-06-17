# Phase 2 — physical cache fallback

Reached when Phase 1 (virtual URI) returns ENOENT/empty after sub-package
resolution. Input: the already-normalized `<DISPLAY_NAME>` from SKILL Step 1.1.
(If you arrive here without normalization — apply Step 1.1 first.)

## F1 — Validate `cache_base`

```powershell
if (Test-Path "<cache_base>/.adt/classlib/classes") { "VALID" } else { "INVALID" }
```

If INVALID, locate the active cache and update `configs/system.md`:

```powershell
$root = "$env:APPDATA\Code\User\workspaceStorage"
Get-ChildItem -LiteralPath $root -Recurse -Directory `
  -Filter "<system_id>" -ErrorAction SilentlyContinue |
  Where-Object { Test-Path "$($_.FullName)\.adt\classlib\classes" } |
  Sort-Object { (Get-Item "$($_.FullName)\.adt\classlib\classes").LastWriteTime } -Descending |
  Select-Object -First 1
```

No result → tell the user the cache is missing and stop.

## F2 — Identify object type

From an ADT path: type label = second-to-last segment (after `Source Code Library`,
`Data Dictionary`, or `Function Library`).

From a bare/display name without type: infer by prefix (`CL_*`/`BP_*` → Class,
`IF_*` → Interface, `R_*`/`I_*`/`C_*`/`P_*` → CDS Data Definition); else ask.

Look up the physical cache subdir → `references/object-types.md`.

## F3 — Encode the object name

Display → encoded:

1. `(NS)NAME` → `/NS/NAME` (strip parens, replace with `/`)
2. lowercase
3. `/` → `%2f`, `#` → `%23`, space → `%20`, other non-`[a-z0-9_]` → percent-encoded

| Display | Encoded |
|---|---|
| `(NS)CL_FOO` | `%2fns%2fcl_foo` |
| `Z_MY_PROG` | `z_my_prog` |
| `LCL_HANDLER#FOO` | `lcl_handler%23foo` |

## F4 — Build cache path

```
<cache_base>/.adt/<subdir>/<encoded_name>/
```

## F5 — Existence check + auto-open retry loop

```powershell
$dir = "<cache_base>/.adt/<subdir>/<encoded_name>"
if (Test-Path $dir) { Get-ChildItem -LiteralPath $dir | Select Name, Length, LastWriteTime }
```

EXISTS — check which files are present:

```powershell
Get-ChildItem -LiteralPath $dir | Select-Object Name, Length
```

Interpret the result:

| Files found | Meaning | Action |
|---|---|---|
| `.aclass` only (no `.acinc`) | Main body cached; parts never opened in editor | Read `.aclass`; tell user local types are unavailable; ask them to open in ADT Project Explorer if parts are needed |
| `.aclass` + `.acinc` files | Fully cached | Read all relevant files per `include_type` |
| Directory empty | Cache entry exists but is hollow | Treat as MISSING → auto-open loop below |

**Do not** attempt virtual URI reads for `.clas.definitions.abap` / `.clas.implementations.abap`
when `.acinc` files are absent — they will return ENOENT. The parts are populated only when
the user opens the class in the editor.

MISSING → derive slash-form name (`(NS)CL_FOO` → `/NS/CL_FOO`; bare stays bare),
trigger auto-open:

```powershell
powershell.exe -ExecutionPolicy Bypass `
  -File "<skills_root>/abap-vs-reader/scripts/open-abap.ps1" `
  -ObjectName "<derived_name>"
```

PowerShell 5.1 `-File` does **not** propagate non-zero exit codes; detect
failure by inspecting stdout/stderr for:

- `ObjectName is required` — empty input
- `ObjectName must be in slash form` — display form was passed
- `VS Code window not found` — focus could not be acquired

Retry loop:

1. Run `open-abap.ps1`.
2. Wait 5 s.
3. Re-check `Test-Path` and non-empty.
4. Still missing → wait 5 s, retry once.
5. After 2 attempts (~12 s) → run Phase 3 fuzzy lookup with a shortened prefix;
   no match → tell the user and stop.

> Activation does not auto-cache — only opening does. Run the loop even when
> the user reports the object was just activated.

> When the script does nothing from the VS Code integrated terminal → see
> `references/troubleshooting.md`.

## F6 — Select files & read

Class files: see "Class file selection by `include_type`" in
`references/object-types.md`. Skip list (`.ap*`, `.$$$`, `.devck`, `.prefs`,
`.project`, `.properties`, `*.texts.*.properties`) is in the same reference.

Read each selected file with `read_file`. Output formatting → SKILL Phase 4.

## Virtual ↔ physical conversion

| Aspect | Virtual `abap:/repotree-v1/` | Physical cache |
|---|---|---|
| Hierarchy | Mirrors package containment | Flat: `system / type subdir / encoded name` |
| Object name | Display `(NS)NAME` | `%2fns%2fname` |
| Per-object layout | Multiple `.clas.<part>.abap` parts in one folder | Real files: `.aclass`, `.acinc`, `.asbdef`, … |

Virtual → physical: take the last URI segment (display name), drop the package
path, identify the type from the second-to-last segment, then run F2 → F4.

Physical → virtual: needed only for display links — combine
`repotree_package_path` from config with the URL-encoded display name.
