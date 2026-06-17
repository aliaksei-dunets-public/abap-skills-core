---
name: abap-vs-reader
description: "Fetch and display SAP ABAP source from the local ADT VS Code workspace. Use whenever the user provides an ADT path starting with `/repotree-v1/`, or asks to read, open, review, inspect, or fetch any ABAP repository object (class, interface, CDS view, BDEF, program, function group, table, structure, data element, domain, etc.)."
---

# abap-vs-reader

Read SAP ABAP source from the local ADT VS Code extension. **Always try the
virtual URI first**; fall back to the physical cache only when virtual fails.

| Route | Path shape | Role |
|---|---|---|
| **Virtual URI** (primary) | `abap:/repotree-v1/<system>/<root>/<package>/.../<TYPE_LABEL>/<DISPLAY_NAME>/<filename>` | Single-object reads. Pull-through fetch for the **main file only** — works even if never opened. Parts (definitions/implementations/macros/testclasses) require prior editor open. |
| **Physical cache** (fallback) | `<cache_base>/.adt/<subdir>/<encoded_name>/<file>.<ext>` | Virtual route fails (ENOENT/empty/network); also for fuzzy lookup, grep, bulk listing. |

`$ARGUMENTS` = ADT path / display name `(NS)NAME` / bare name + optional
`include_type` (`all` default | `main` | `definitions` | `implementations` |
`testclasses` | `macros`).

## Phase 0 — Parse & resolve config

- Extract `input_path` and `include_type` from `$ARGUMENTS`.
- Read `configs/system.md` and `project-config.md`. Required fields and
  fallbacks → `CONFIG_TEMPLATE.md`.
- If input is bare (no `(NS)`/`/NS/`) and `Z*`/`Y*`, keep bare; otherwise
  prepend `primary_namespace`. If missing, ask the user.
- If the segment after `/repotree-v1/` in `input_path` ≠ `system_id`, warn but continue.

## Phase 1 — Virtual URI (primary)

### Step 1.1 — Normalize to display form `<DISPLAY_NAME>`

- `/demo/cl_foo` → `(DEMO)CL_FOO` (replace `/NS/` with `(NS)`, uppercase).
- `(demo)cl_foo` → `(DEMO)CL_FOO` (uppercase).
- `Z_FOO` / `Y_FOO` → keep bare.
- Bare non-`Z`/`Y` → prepend `(<primary_namespace>)`.

### Step 1.2 — Construct the URI + pre-check physical cache

**Before** calling `read_file`, run a one-line cache pre-check to know what files
exist locally (costs nothing, saves retries):

```powershell
$encoded = "<encoded_name>"  # F3 encoding from references/cache-fallback.md
Get-ChildItem -LiteralPath "<cache_base>/.adt/<subdir>/$encoded" -ErrorAction SilentlyContinue |
  Select-Object Name, Length
```

Use the result to set expectations:
- `.aclass` present → main body is readable from cache; virtual URI should also work.
- `.acinc` files present → parts (definitions/implementations/etc.) are available.
- **No `.acinc` files** → parts were never cached; do NOT attempt virtual URI reads for
  `.clas.definitions.abap` etc. — they will ENOENT. Read `.aclass` now and tell the user
  that local types are unavailable until they open the class in the ADT Project Explorer.

Then construct the URI:

```
abap:/repotree-v1/<system_id>/<virtual_root_segment>/<virtual_top_package>/<SUB_PACKAGE_CHAIN>/<TYPE_LABEL>/<DISPLAY_NAME>/<filename>
```

- `<TYPE_LABEL>` and `<filename>` suffix per type → `references/object-types.md`.
- `<SUB_PACKAGE_CHAIN>`: first matching pattern in `virtual_known_subpackages`,
  else `virtual_default_subpackage_chain`, else empty.
- Casing & literal-passing rules (no pre-encoding of spaces/parens) →
  `references/object-types.md`.

### Step 1.3 — Read

Call `read_file` on the URI.

| Outcome | Next |
|---|---|
| Returns ABAP keywords (`CLASS`, `INTERFACE`, `MANAGED`, `DEFINE`, `REPORT`, `@…`) | Phase 4 |
| ENOENT / "Unable to resolve nonexistent file" | Step 1.4; on second ENOENT → Phase 2 |
| Empty content | Retry once after 2 s; still empty → Phase 2 |
| HTTP / network error | Tell user to reconnect ADT extension; stop |

### Step 1.4 — Resolve sub-package chain (only on ENOENT)

Cheapest → most expensive:

1. Retry with **no** `<SUB_PACKAGE_CHAIN>` (object directly under top package).
2. Phase 3 fuzzy lookup (free — local cache grep, no ADT requests).
3. Ask the user to open the object manually in VS Code (`Ctrl+Shift+A` → type the name → Enter), then retry Phase 1 after they confirm.

Do **not** call `list_dir` to hunt for the sub-package — it burns tokens and ADT requests for every subfolder. The user's one-time manual open is cheaper overall.

Persist confirmed sub-package mappings to `/memories/repo/` after a successful read to skip this step next time.

### Step 1.5 — Class file selection

Class folder exposes `.clas.abap` plus `.clas.<part>.abap` parts. Apply
`include_type` per the table in `references/object-types.md`. Behavior pools
(`BP_R_*`) are global classes — same selection. For huge classes read
`.clas.abap` first, then read relevant line ranges of part files via
`read_file` line-range parameters.

## Phase 2 — Fallback: physical cache

Use only after Phase 1 returned ENOENT/empty (post sub-package resolution).
The normalized `<DISPLAY_NAME>` from Step 1.1 is the input.

Procedure (validate `cache_base` → encode name → build path → auto-open retry
loop → read → present), `open-abap.ps1` invocation, failure-detection
substrings, and virtual ↔ physical conversion → `references/cache-fallback.md`.

## Phase 3 — Fuzzy / partial-name lookup

When the user gives an approximate name. Strategy: physical cache acts as the
**index of locally known names**; on a hit return to Phase 1 for canonical reading.

```powershell
Get-ChildItem -LiteralPath "<cache_base>/.adt/<subdir>" `
  -Directory -Filter "*<partial_lowercase>*"
```

If type unknown, search across likely subdirs (classes, interfaces, ddlsources,
bdef, programs). Decode each match (`%2fns%2fcl_foo` → `(NS)CL_FOO`) before
presenting.

| Outcome | Next |
|---|---|
| One match | Use decoded name → Phase 1 |
| Multiple matches | Show decoded list; ask user to pick |
| Zero in cache | Ask the user for the exact name **or** the parent package, then `list_dir` that package's virtual URI |

## Phase 4 — Present

```
── <filename> ──────────────────────────────
<content>
```

Multiple files: blank line between sections. Line-range reads: prepend
`(lines N-M)` to the label. Skip ADT metadata files (list →
`references/object-types.md`).

## References

- `CONFIG_TEMPLATE.md` — required + optional config fields.
- `references/object-types.md` — type mapping (virtual labels + cache subdirs +
  extensions), casing/encoding rules, class file selection table, skip list.
- `references/cache-fallback.md` — Phase 2 procedure (cache validation, name
  encoding, auto-open loop, virtual↔physical conversion).
- `references/troubleshooting.md` — known issues + symptom table. Read first
  when something fails.
- `references/recipes.md` — copy-pasteable PowerShell snippets.
- `references/tests.md` — `open-abap.ps1` test suite.
