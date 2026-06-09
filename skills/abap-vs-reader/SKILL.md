# abap-vs-reader — Core Skill

Fetch and display SAP ABAP artifact source code from the local ADT VSCode extension
cache. Use whenever the user provides an ADT path starting with `/repotree-v1/`, or
asks to read, open, review, inspect, or fetch an ABAP class, interface, CDS view,
Behavior Definition (BDEF), program, function group, database table, structure, data
element, or domain. Reads from the local ADT semantic cache populated by the SAP ADT
for VSCode extension.

Arguments: $ARGUMENTS — an ADT path of the form
`/repotree-v1/<SYSTEM>/.../<OBJECT_TYPE>/<OBJECT_NAME>`
and optionally an include type: `all` (default), `implementations`,
`testclasses`, `definitions`, `main`.

Parse $ARGUMENTS to extract:
- `input_path` — the full `/repotree-v1/...` string (or a bare/display-format object name if the user provides just a name)
- `include_type` — the include keyword if present, otherwise `all`

---

## Phase 0 — Choose the right lookup strategy

The ADT VSCode extension exposes ABAP objects through **two surfaces**, and each
surface requires a different access strategy. Picking the wrong one is the most
frequent reason an artifact appears "missing" while it actually exists in the
system.

| Surface | Path shape | Use it for | Tools that work |
|---|---|---|---|
| **Virtual workspace** (live, in-memory) | `abap:/repotree-v1/<system_id>/...` with display names like `(NS)CL_FOO` | Editing the object live in the editor; clicking jump-to-definition | `read_file` (when the user already has the file open) |
| **Physical semantic cache** (on-disk) | `<cache_base>/.adt/<subdir>/<encoded_name>/<file>.<ext>` | Bulk reading, grep/search across many objects, reading without opening | `read_file`, `grep_search`, `Get-ChildItem`, `Select-String` |

### Rules of thumb

1. **Never `file_search` for ABAP source by user-friendly name** (`bp_r_foo.clas.implementations.abap`). The physical cache uses **encoded URL paths** (`%2fns%2fbp_r_foo`) and **non-standard extensions** (`.aclass`, `.acinc`, `.asbdef`, `.asddls` …). Vanilla glob patterns will not find them.
2. **Always resolve to the physical cache** when:
   - You need to read source code body to inspect logic
   - You need to grep across multiple unrelated objects
   - The object is not currently open in any editor tab
3. **The virtual `repotree-v1` path describes only logical placement** (package / sub-package). It does **not** influence the physical cache path. In the cache, the only locators are: `system_id`, `object_type` subdirectory, and `encoded_object_name`. Two objects with the same name in different sub-packages share the same physical path.
4. **For partial / fuzzy lookups** (user mentions an approximate name), `Get-ChildItem -Filter "*partial*" -Directory` against the appropriate `<cache_base>/.adt/<subdir>/` is the **only** reliable approach. See Step 2.5b.

---

## Phase 1 — Resolve Config

Read the system details from `configs/system.md` (already loaded via `config.md`).

Extract the following fields from `configs/system.md`:
- `system_id` — the SAP system connection ID (e.g. `DEMO_001_EN`)
- `cache_base` — the full path to the ADT VSCode extension cache root for this system
- `repotree_package_path` — the package path segment used in repotree URIs (e.g. `System%20Library/(DEMO)PKG/Source%20Library/(DEMO)PKG`)

If any of these fields are missing or the file does not exist, tell the user which
field is missing, refer them to `configs/system.md`, and stop.

### Step 1.1 — Validate cache_base

VSCode can create multiple `workspaceStorage` directories for the same workspace over
time. Validate that the configured `cache_base` is active before proceeding.

Run:
```bash
ls "<cache_base>/.adt/classlib/classes/" 2>/dev/null && echo "VALID" || echo "INVALID"
```

**If VALID:** proceed to Phase 2.

**If INVALID:** the configured `cache_base` is stale. Search all `workspaceStorage`
directories for the active ADT cache for this system:

```bash
find "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "<cache_base>")")")")")")")")" \
  -maxdepth 12 -type d \
  -path "*/SAPSE.adt-vscode/adtWorkspace/.metadata/.plugins/org.eclipse.core.resources.semantic/.cache/<system_id>/.adt/classlib/classes" \
  2>/dev/null
```

Where `<system_id>` is the value from config.

- If **one result** is found: derive the new `cache_base` by stripping `/.adt/classlib/classes`
  from the found path. Update `cache_base` in `configs/system.md`, inform the user, and continue.
- If **multiple results** are found: pick the one with the most recently modified
  `.adt/classlib/classes/` directory (run `ls -lt` on each result and take the first).
  Update `cache_base` in `configs/system.md`, inform the user, and continue.
- If **no result** is found: tell the user the ADT cache for `<system_id>` was not
  found in any `workspaceStorage`, and stop.

---

## Phase 2 — Resolve and Read Artifact

### Step 1 — Normalize the object name to display format

The user may provide the object name in several formats. Normalize to **display format**
(`(NS)OBJECT_NAME` uppercase) using this table:

| Input example | Rule | Result |
|---|---|---|
| `/demo/cl_foo` | Replace `/NS/` prefix with `(NS)`, uppercase | `(DEMO)CL_FOO` |
| `(DEMO)CL_FOO` | Already display format, uppercase | `(DEMO)CL_FOO` |

If the input is a **bare name with no namespace prefix** (e.g. `CL_FOO`, `Z_MY_PROG`),
read the `primary_namespace` field from `project-config.md` and prepend it:
`(PRIMARY_NS)CL_FOO`. If `project-config.md` does not define `primary_namespace`, ask
the user to supply the namespace.

### Step 2.1 — Extract system ID from the ADT path

The ADT path segment immediately after `/repotree-v1/` is the system connection ID
(e.g. `DEMO_001_EN`). Lowercase it. Compare against the lowercased `system_id`
from `configs/system.md`. If they do not match, warn the user that the path is for a
different system but continue using the `cache_base` from config.

### Step 2.2 — Extract the object type segment and object name

Scan the ADT path from right to left:
- The **last** segment is the object name, e.g. `(NS)CL_FOO`
- The **second-to-last** segment is the object type label, e.g. `Classes`

The type label appears after one of these keywords in the path:
`Source Code Library`, `Data Dictionary`, `Function Library`.

If the input is a bare or display-format name (not a full ADT path), skip Steps 2.1
and 2.2. Use the normalized display name from Step 1 as the object name, and ask the
user for the object type (or infer it from context if obvious, e.g. `CL_` prefix
implies `Classes`).

### Step 2.3 — Map object type label to ADT subdirectory

The ADT VSCode extension stores each object type in its own subdirectory under
`<cache_base>/.adt/`. Use the table below to map the path segment (or the user-supplied
hint) to the correct subdirectory and source file extension.

| Path segment / object type hint | `.adt/` subdirectory | Source extension(s) | Notes |
|---|---|---|---|
| `Classes` | `classlib/classes` | `.aclass` (main signature), `.acinc` (definitions / implementations / testclasses / macros) | Multi-file object — see Step 2.7 |
| `Interfaces` | `classlib/interfaces` | `.aint` | Single file |
| `Programs` | `programs` | `.prog` | Reports, executables |
| `Includes` | `programs/includes` | `.prog` | Stand-alone include programs |
| `Function Groups` | `functions/groups` | `.fugr` | Container; individual function modules nested below |
| `Function Modules` | `functions/groups/<group>/modules` | `.fugr.func` | Look up via the function group first |
| `Type Groups` | `programs/typegroups` | `.prog` | Legacy global type pools |
| `Message Classes` | `programs/messageclasses` | `.prog.msag` | Source contains message texts |
| `Data Definitions` (CDS view) | `ddic/ddlsources` | `.asddls` | Single file |
| `Metadata Extensions` (CDS MDX) | `wbobj2/ddic/ddlxex` | `.asddlxex` | Single file |
| `Behavior Definitions` (BDEF) | `wbobj2/bo/bdef` | `.asbdef` | Single file containing the full BDEF source |
| `Behavior Implementations` | `classlib/classes` | `.aclass`, `.acinc` | Behavior pools (`BP_R_…`) are normal global classes — read like classes |
| `Service Definitions` | `ddic/srvdsources` | `.assrvds` | Single file |
| `Service Bindings` | `wbobj/businessservices/bindings` | `.srvbsvb` | XML metadata only — there is no human-editable ABAP source |
| `Database Tables` | `ddic/tables` | `.tabl` | Field list + key in DDIC source |
| `Structures` | `ddic/structures` | `.stru` | Single file |
| `Data Elements` | `ddic/dataelements` | `.dtel` | Single file |
| `Domains` | `ddic/domains` | `.doma` | Single file |
| `Search Helps` | `ddic/searchhelps` | `.shlp` | Single file |
| `Lock Objects` | `ddic/lockobjects` | `.enqu` | Single file |
| `Table Types` | `ddic/tabletypes` | `.ttyp` | Single file |
| `Type Definitions` (DDIC type) | `ddic/types` | `.type` | Single file |
| `Authorization Objects` | `wbobj/authorizationobjects` | `.auth` | Where applicable |
| `Number Range Objects` | `wbobj/numberrangeobjects` | `.nrobj` | Where applicable |

**Files to skip** — these are ADT metadata, not source. They appear alongside the
real source in the same object directory:

```
.apclass  .apint  .apddls  .apddlxex  .apbdef  .apsrvds
.aptec  .astec  .$$$  .prefs  .project  .properties  .devck
```

If the type label is not in this table, fall back to scanning `<cache_base>/.adt/`
recursively for a directory whose encoded name matches the object (see Step 2.5b),
and warn the user that the type was inferred.

### Step 2.4 — Encode the object name

The cache directory uses URL-encoded lowercased object names. Apply the rules in
order:

1. **Strip parentheses** from the namespace prefix and replace with slashes:
   `(NS)OBJECT` → `/NS/OBJECT`
2. **Lowercase** the entire name: `/NS/OBJECT` → `/ns/object`
3. **URL-encode every `/`** as `%2f`: `/ns/object` → `%2fns%2fobject`
4. **URL-encode special characters** that may appear in object names:
   - `#` → `%23`  (used in some legacy / generated includes)
   - space → `%20` (rare, but possible in description-driven names)
   - any other non-`[a-z0-9_]` character → its lowercase percent-encoding

| Display name | Encoded cache directory name |
|---|---|
| `(NS)CL_FOO` | `%2fns%2fcl_foo` |
| `(NS)R_BAR` | `%2fns%2fr_bar` |
| `Z_MY_PROG` (no namespace) | `z_my_prog` |
| `ZCL_HANDLER` (no namespace) | `zcl_handler` |
| `LCL_HANDLER#FOO` (with `#`) | `lcl_handler%23foo` |

> **Always lowercase before encoding.** The cache is case-sensitive on its directory
> names and uses lowercase exclusively.

### Step 2.5 — Build the object cache directory path

```
<cache_base>/.adt/<subdirectory>/<encoded_name>/
```

Examples:

| Object | Cache directory |
|---|---|
| Class `(NS)CL_FOO` | `<cache_base>/.adt/classlib/classes/%2fns%2fcl_foo/` |
| BDEF `(NS)R_FOO` | `<cache_base>/.adt/wbobj2/bo/bdef/%2fns%2fr_foo/` |
| CDS view `(NS)R_FOO` | `<cache_base>/.adt/ddic/ddlsources/%2fns%2fr_foo/` |
| Behavior pool `(NS)BP_R_FOO` | `<cache_base>/.adt/classlib/classes/%2fns%2fbp_r_foo/` |
| Z-program `Z_MY_PROG` | `<cache_base>/.adt/programs/z_my_prog/` |

> **`wbobj` vs `wbobj2`:** the ADT extension keeps newer object types (CDS-based
> RAP artifacts: BDEF, MDX) under `wbobj2/`, while older / non-RAP repository
> objects (service bindings, authorization objects) live under `wbobj/`. If
> Step 2.3 directs you to one of these, use exactly that path — they are not
> interchangeable.

### Step 2.5b — Fuzzy / partial-name lookup

When the user supplies an approximate object name (e.g. *"open the order
handler class"* without the exact prefix), do **not** rely on `file_search`
against the workspace —
the physical cache uses encoded names that glob patterns will not match. Instead,
list the relevant subdirectory and filter:

```powershell
Get-ChildItem `
  -LiteralPath "<cache_base>/.adt/<subdirectory>" `
  -Directory `
  -Filter "*<partial_lowercase>*"
```

If the user gave only a partial **without** specifying the object type, run the
same `Get-ChildItem` across **all** likely subdirectories (classes, interfaces,
ddlsources, bdef, programs) and present the matches to the user for disambiguation.
Always present the **decoded** display name (`%2fns%2fcl_foo` → `(NS)CL_FOO`) when
listing matches.

### Step 2.6 — Check the directory exists; auto-open retry loop

Use the OS-appropriate listing command:

```powershell
# PowerShell (Windows)
if (Test-Path "<object_cache_dir>") { "EXISTS" } else { "MISSING" }
```

```bash
# bash / git-bash
[ -d "<object_cache_dir>" ] && echo "EXISTS" || echo "MISSING"
```

**If EXISTS:** verify the directory is **non-empty and recent** before reading.
A stale or partially populated directory can exist from a previous session:

```powershell
Get-ChildItem -LiteralPath "<object_cache_dir>" |
  Select-Object Name, Length, LastWriteTime
```

If the directory is empty, or all files are older than the user's last save of the
object, treat it as MISSING and trigger the auto-open loop.

**If MISSING (or stale):** derive the open-object name from the parsed object name —
strip parentheses, insert `/`, uppercase — to get the slash-namespaced form
(e.g. `(NS)CL_FOO` → `/NS/CL_FOO`; bare `Z_FOO` stays `Z_FOO`). Then trigger the
ADT VSCode "Open Object" command:

```powershell
powershell.exe -ExecutionPolicy Bypass `
  -File "<skills_root>/abap-vs-reader/scripts/open-abap.ps1" `
  -ObjectName "<derived_name>"
```

(From a non-Windows host with MSYS / Git Bash, prefix with
`MSYS_NO_PATHCONV=1` and call `powershell.exe` directly.)

> **Detecting script failure:** Windows PowerShell 5.1 invoked via `-File` does
> not reliably propagate non-zero exit codes from `throw` or `exit N` to the
> parent process — `$LASTEXITCODE` will usually be `0` even when validation
> failed. Detect failures by inspecting the script's **stderr/stdout** output
> for one of these substrings:
>
> - `ObjectName is required` — empty / whitespace input
> - `ObjectName must be in slash form` — display-form `(NS)NAME` was passed
> - `VS Code window not found` — focus could not be acquired
>
> If any of these appear, fix the input (Step 2.4) or the environment and retry.

**Retry loop**:

1. Run `open-abap.ps1`.
2. Wait **5 seconds** (the ADT extension needs time to fetch from the server and
   populate the cache; busy systems can be slower).
3. Re-check `Test-Path <object_cache_dir>`.
4. If EXISTS and non-empty → proceed to Step 2.7.
5. If still MISSING → wait another 5 seconds, retry once more.
6. After **2 total open attempts** (≈ 12 seconds elapsed), if still MISSING:
   - Run Step 2.5b fuzzy lookup with a shortened prefix of the object name to
     check whether the object exists under a slightly different name.
   - If no match, inform the user the object could not be found and stop.

> **Newly-created or just-activated objects:** the ADT extension does not
> always proactively cache an object until it is explicitly opened in an editor
> tab. Always run the auto-open loop **even if** the user reports that the object
> was just activated — activation does not guarantee a cache entry.

### Step 2.7 — Select files to read

**Class objects** (`classlib/classes`) — multi-file. The directory contains one
`.aclass` file (the global signature / public+protected+private sections) plus
zero or more `.acinc` includes. Apply the `include_type` filter:

| `include_type` | Files to read |
|---|---|
| `all` (default) | `.aclass` first, then every `.acinc` (definitions, implementations, testclasses, macros) |
| `implementations` | `*implementations.acinc` only |
| `testclasses` | `*testclasses.acinc` only |
| `definitions` | `*definitions.acinc` only |
| `macros` | `*macros.acinc` only |
| `main` | `.aclass` only (use this for large classes when you only need the signature / method list) |

> **Performance tip for large classes:** when the implementation file is huge
> (> 1000 lines), prefer reading `.aclass` first to obtain the full method list,
> then read only the relevant ranges of `.acinc` via line-range parameters of the
> `read_file` tool, rather than streaming the whole include.

**Interfaces** (`classlib/interfaces`): read the single `.aint` file.

**Behavior pools** (e.g. `BP_R_<root>`): they live in `classlib/classes` and are
treated exactly like normal classes — the same `include_type` filter applies. The
RAP-specific local handlers are inside `*implementations.acinc`.

**All other object types**: read the single source file matching the extension from
the Step 2.3 table.

**Always skip** these files (ADT metadata / texts / project artefacts):

```
.apclass  .apint  .apddls  .apddlxex  .apbdef  .apsrvds
.aptec  .astec  .$$$  .prefs  .project  .properties  .devck
*.texts.*.properties   (translatable texts, not source)
```

### Step 2.8 — Read and return the source

Read each selected file using the `read_file` tool. Present each file labelled by
filename:

```
── <filename> ──────────────────────────────
<content>
```

If multiple files are read, separate them with blank lines between the labelled
sections. When line-range parameters were used (large classes), prepend the range
to the label: `── <filename> (lines 100-250) ──`.

### Step 2.9 — Virtual workspace ↔ physical cache mapping

The `abap:/repotree-v1/...` virtual paths shown in the editor and the physical
cache paths under `<cache_base>/.adt/...` are **independent representations of the
same object** and follow different schemes:

| Aspect | Virtual `abap:/repotree-v1/` path | Physical cache path |
|---|---|---|
| Hierarchy | Mirrors **package / sub-package** structure | Flat — only `system_id / type_subdir / encoded_name` |
| Object name | Display format `(NS)NAME` (URL-encoded as `%28NS%29NAME`) | Slash-form `/ns/name` (URL-encoded as `%2fns%2fname`) |
| Per-object layout | Multiple "virtual" `.clas.<part>.abap` files inside one folder | Real files with native ADT extensions (`.aclass`, `.acinc`, `.asbdef` …) |
| Re-mapping required? | Yes — for every read | No — once you have the physical path, read directly |

**Conversion rule (virtual → physical):**

1. Take the **last path segment** of the repotree URI — that is the object name in
   display format (URL-decoded).
2. Drop the package path entirely; it is **not** used to locate the file in the
   cache.
3. Identify the object type from the second-to-last segment (Step 2.2).
4. Apply Steps 2.3 → 2.5 to construct the physical path.

**Conversion rule (physical → virtual):** in general unnecessary. Only required if
you need to display a clickable link back to the user, in which case combine the
configured `repotree_package_path` with the URL-encoded display name.

---

## Phase 3 — Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `file_search` returns nothing for a known object | Searching by user-friendly name in the cache (which uses encoded names) | Use Step 2.5b `Get-ChildItem -Filter` instead |
| `Test-Path` reports MISSING for an object that exists in the system | Object never opened in this VS Code session → not yet cached | Run the auto-open loop (Step 2.6) |
| Cache directory exists but is empty | ADT extension was interrupted during fetch | Re-trigger auto-open; if still empty after 2 attempts, restart the ADT extension |
| `cache_base` validation fails (Step 1.1) | VS Code created a new `workspaceStorage` directory | Run the `find` recovery in Step 1.1 to relocate the active cache |
| Read returns ADT metadata XML instead of ABAP source | A `.ap*` / `.$$$` / `.devck` file was selected | Re-apply the skip list in Step 2.7 |
| Two different objects map to the same physical path | They share a name across systems but the configured `system_id` is wrong | Re-check Step 2.1 — system ID must match the path segment after `/repotree-v1/` |
| Just-activated object is not visible | Activation does not auto-cache; only opening does | Always run auto-open loop after activation, regardless of "object exists" claims |
| Class implementation file is huge and reads slow | Reading whole `.acinc` instead of using line ranges | Read `.aclass` first; then read only relevant method ranges from the include |
| Behavior pool (`BP_R_…`) not found under `wbobj2/bo/bdef/` | BP is a global class, not a BDEF artefact | Look in `classlib/classes/` instead |
| Service binding has no readable source | SRVB stores XML metadata only | Read the linked Service Definition (`.assrvds`) for the projection source |

---

## Phase 4 — Quick recipes

Copy-pasteable PowerShell snippets for the most common needs.

### List all objects of a given type in the cache

```powershell
Get-ChildItem -LiteralPath "<cache_base>/.adt/<subdir>" -Directory |
  Select-Object @{N='Decoded';E={ [System.Web.HttpUtility]::UrlDecode($_.Name).ToUpper() }}
```

### Find every object whose name contains a substring (any type)

```powershell
$subdirs = @(
  'classlib/classes', 'classlib/interfaces',
  'ddic/ddlsources', 'ddic/tables', 'ddic/structures',
  'wbobj2/bo/bdef', 'ddic/srvdsources', 'programs'
)
foreach ($s in $subdirs) {
  Get-ChildItem -LiteralPath "<cache_base>/.adt/$s" -Directory -Filter "*<partial>*" -EA SilentlyContinue |
    ForEach-Object { "$s : $($_.Name)" }
}
```

### Grep across a whole class (signature + all includes)

```powershell
Get-ChildItem -LiteralPath "<object_cache_dir>" -Include *.aclass,*.acinc -File |
  Select-String -Pattern '<regex>'
```

### Confirm the cache is alive after activation

```powershell
$dir = "<object_cache_dir>"
if (Test-Path $dir) {
  Get-ChildItem -LiteralPath $dir |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 5 Name, Length, LastWriteTime
}
```

If the most recent `LastWriteTime` is older than the user's last activation,
re-trigger the auto-open loop.

---

## Phase 5 — Tests

The skill ships a self-contained test suite under
`scripts/tests/` that validates the input contract of `open-abap.ps1`
without touching VS Code or the keyboard. The runner has **zero
dependencies** -- it does not require Pester or any external module.

### Layout

```
scripts/
  open-abap.ps1
  tests/
    Invoke-Tests.ps1        # discovery + runner (no dependencies)
    open-abap.Tests.ps1     # tests for open-abap.ps1
```

### Run the suite

From any shell on Windows:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File "<skills_root>/abap-vs-reader/scripts/tests/Invoke-Tests.ps1"
```

Optional `-Filter '<wildcard>'` to run a subset:

```powershell
.\Invoke-Tests.ps1 -Filter '*display-form*'
```

### Exit codes

| Code | Meaning |
|---|---|
| `0` | All tests passed |
| `1` | At least one test failed |
| `2` | Runner failure (no `*.Tests.ps1` files found, etc.) |

### When to run

- **After editing `open-abap.ps1`** -- always; the validation messages are
  documented in Step 2.6 of this skill as failure-detection substrings, so any
  wording change must keep the tests green.
- **Before committing changes to the core repository.**
- **As part of the `abap-skill-manager validate` command** -- the manager runs
  every skill's `scripts/tests/Invoke-Tests.ps1` automatically when present.

### Adding more tests

Drop a new `*.Tests.ps1` file alongside `Invoke-Tests.ps1`. Use the simple DSL:

```powershell
Test 'short description of the case' {
    Assert-Equal 'expected' 'actual'
    Assert-True  ($x -gt 0)
    Assert-Match 'pattern' $someText
    Assert-Throws { Bad-Call }
    Assert-NotMatch 'forbidden' $someText
}
```

The runner discovers every `*.Tests.ps1` in the directory and treats each `Test`
block as an independent case -- a failure in one block does not abort the rest.
