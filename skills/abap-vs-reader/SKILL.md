---
name: abap-vs-reader
description: "Read SAP ABAP source from the local ADT VS Code workspace. Use when the user provides an ADT path starting with `/repotree-v1/`, or asks to read, open, review, inspect, or fetch any ABAP repository object."
---

# abap-vs-reader

Read SAP ABAP source via virtual URIs served by the local ADT VS Code extension.
Always use virtual URIs. If a file cannot be found, ask the user to open the object manually in VS Code.

`$ARGUMENTS` = ADT path / display name `(NS)NAME` / bare name + optional
`include_type` (`all` default | `main` | `definitions` | `implementations` | `testclasses` | `macros`).

## Phase 0 — Parse & resolve config

- Extract `input_path` and `include_type` from `$ARGUMENTS`.
- Read `configs/system.md` (required: `system_id`, `virtual_root_segment`, `virtual_top_package`; optional: `virtual_default_subpackage_chain`, `virtual_known_subpackages`) and `project-config.md` (required: `primary_namespace`). See `CONFIG_TEMPLATE.md` for format.
- If input is bare (no `(NS)`/`/NS/`) and `Z*`/`Y*`, keep bare; otherwise prepend `primary_namespace`. If missing, ask the user.

## Phase 1 — Virtual URI

### Step 1.1 — Normalize to display form `<DISPLAY_NAME>`

- `/demo/cl_foo` → `(DEMO)CL_FOO` (replace `/NS/` with `(NS)`, uppercase).
- `(demo)cl_foo` → `(DEMO)CL_FOO` (uppercase).
- `Z_FOO` / `Y_FOO` → keep bare.
- Bare non-`Z`/`Y` → prepend `(<primary_namespace>)`.

### Step 1.2 — Construct the URI

```
abap:/repotree-v1/<system_id>/<virtual_root_segment>/<virtual_top_package>/<SUB_PACKAGE_CHAIN>/<TYPE_LABEL>/<DISPLAY_NAME>/<filename>
```

- `<SUB_PACKAGE_CHAIN>`: first matching pattern in `virtual_known_subpackages`, else `virtual_default_subpackage_chain`, else empty.
- Pass spaces and parens **literally** — do not pre-encode. `read_file` URL-encodes internally; pre-encoding produces ENOENT.
- `<DISPLAY_NAME>`: uppercase. `<filename>` prefix: lowercase display form, e.g. `(hec4)cl_foo.clas.abap`.
- `<TYPE_LABEL>` and `<filename>` suffix → `references/object-types.md`.

### Step 1.3 — Read

Call `read_file` on the URI.

| Outcome | Next |
|---|---|
| Returns ABAP source | Phase 2 |
| ENOENT / "Unable to resolve nonexistent file" | Step 1.4 |
| Empty content | Retry once after 2 s; still empty → Step 1.4 |
| HTTP / network error | Tell user to reconnect ADT extension; stop |

### Step 1.4 — Resolve sub-package chain (only on ENOENT)

1. Retry with **no** `<SUB_PACKAGE_CHAIN>` (object directly under top package).
2. If still ENOENT — ask the user to open the object in VS Code (`Ctrl+Shift+A` → type the name → Enter), then retry Step 1.2 after they confirm.

Do not call `list_dir` to hunt for the sub-package.

Persist confirmed sub-package mappings to `/memories/repo/` to skip this step next time.

### Step 1.5 — Class file selection

Apply `include_type` per `references/object-types.md`. Behavior pools (`BP_R_*`) are global classes — same selection. For large classes read `.clas.abap` first, then relevant line ranges of part files.

## Phase 2 — Present

```
── <filename> ──────────────────────────────
<content>
```

Multiple files: blank line between sections. Line-range reads: prepend `(lines N-M)` to the label.
