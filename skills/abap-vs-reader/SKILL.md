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
- The **last** segment is the object name, e.g. `(DEMO)BP_R_UPLOADER`
- The **second-to-last** segment is the object type label, e.g. `Classes`

The type label appears after one of these keywords in the path:
`Source Code Library`, `Data Dictionary`, `Function Library`.

If the input is a bare or display-format name (not a full ADT path), skip Steps 2.1
and 2.2. Use the normalized display name from Step 1 as the object name, and ask the
user for the object type (or infer it from context if obvious, e.g. `CL_` prefix
implies `Classes`).

### Step 2.3 — Map object type label to ADT subdirectory

| Path segment / object type hint | `.adt/` subdirectory | Source extension(s) |
|---|---|---|
| `Classes` | `classlib/classes` | `.aclass`, `.acinc` |
| `Interfaces` | `classlib/interfaces` | `.aint` |
| `Data Definitions` | `ddic/ddlsources` | `.asddls` |
| `Metadata Extensions` | `wbobj2/ddic/ddlxex` | `.asddlxex` |
| `Behavior Definitions` | `wbobj2/bo/bdef` | `.asbdef` |
| `Service Definitions` | `ddic/srvdsources` | `.assrvds` |
| `Service Bindings` | `wbobj/businessservices/bindings` | `.srvbsvb` (XML metadata only) |
| `Programs` | `programs` | `.prog` |
| `Function Groups` | `functions/groups` | `.fugr` |
| `Database Tables` | `ddic/tables` | `.tabl` |
| `Structures` | `ddic/structures` | `.stru` |

Skip files with these extensions — they are ADT metadata, not source:
`.apclass`, `.apint`, `.apddls`, `.apddlxex`, `.apbdef`, `.apsrvds`, `.aptec`, `.$$$`

If the type label is not in this table, use `wbobj` as a fallback and warn the user.

### Step 2.4 — Encode the object name

Convert the display-format name to the cache directory encoding:

1. Strip parentheses from the namespace prefix, replace with `/`: `(DEMO)` → `/DEMO/`
2. Lowercase: `/demo/bp_r_uploader`
3. Replace every `/` with `%2f`: `%2fdemo%2fbp_r_uploader`

For names without a namespace prefix (e.g. `Z_MY_PROG`), simply lowercase:
`z_my_prog`.

### Step 2.5 — Build the object cache directory path

```
<cache_base>/.adt/<subdirectory>/<encoded_name>/
```

Example:
```
<cache_base>/.adt/classlib/classes/%2fdemo%2fcl_foo/
```

### Step 2.6 — Check the directory exists; auto-open retry loop

Run:
```bash
ls "<object_cache_dir>" 2>/dev/null && echo "EXISTS" || echo "MISSING"
```

**If EXISTS:** use the `ls` output to proceed to Step 2.7.

**If MISSING:** derive the open-object name from the parsed object name — strip
parentheses, insert `/`, uppercase — to get the slash-namespaced form (e.g.
`(DEMO)CL_FOO` → `/DEMO/CL_FOO`). Then run:

```bash
MSYS_NO_PATHCONV=1 powershell.exe -File ".claude/skills-core/skills/abap-vs-reader/scripts/open-abap.ps1" -ObjectName "<derived_name>"
```

Retry loop: wait 3 seconds, re-check the directory. Repeat once more (2 attempts
total). If the directory is still MISSING after 2 attempts, inform the user that the
object could not be found in the cache and stop.

### Step 2.7 — Select files to read

**For class objects** (`classlib/classes`): apply the `include_type` filter:

| `include_type` | Files to read |
|---|---|
| `all` (default) | `.aclass` + all `.acinc` (`definitions`, `implementations`, `testclasses`, `macros`) |
| `implementations` | `*implementations.acinc` only |
| `testclasses` | `*testclasses.acinc` only |
| `definitions` | `*definitions.acinc` only |
| `main` | `.aclass` only |

**For interface objects** (`classlib/interfaces`): read the `.aint` file.

**For all other object types**: read the single source file matching the extension from the Step 2.3 table. Skip `.ap*`, `.$$$`, `.astec`, `.prefs`, `.project`, `.properties`, `.devck` — these are ADT metadata/text elements, not editable source.

### Step 2.8 — Read and return the source

Read each selected file using the Read tool. Present each file labelled by filename:

```
── <filename> ──────────────────────────────
<content>
```

If multiple files are read, separate them with blank lines between the labelled
sections.
