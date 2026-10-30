# Output Examples

Reference outputs for `init`, `status`, and `validate`. Use these as the
canonical layout — keep the column order and headings stable so users can
diff successive runs.

---

## `init` — Summary table (both modes)

| Skill | Wrapper | Config | Action |
|---|---|---|---|
| abap-code-review | ✓ | ✓ | skipped (already present) |
| abap-doc-writer | created | generated | ✓ |
| abap-unit-test-creator | created | generated | ✓ |
| abap-vs-reader | created | generated | ✓ |
| abap-wiki-doc-creator | created | generated | ✓ |
| abap-skill-manager | ✓ | — | skipped (no config required) |

Follow with: "Edit `$SKILLS_PATH/project-config.md` and each
`configs/config.md` — all TODO markers must be replaced with real values.
Run `abap-skill-manager validate` to check for missing required fields."

---

## `status` — Submodule mode

```
## Skills Status

Install mode: submodule
Core: <current-SHA>  Upstream: <cached-SHA or unavailable>  Freshness: <known / unknown>

| Skill                  | Wrapper | Config | TODOs | Notes                         |
|------------------------|---------|--------|-------|-------------------------------|
| abap-code-review       | ✓       | ✓      | 0     |                               |
| abap-doc-writer        | ✓       | ✓      | 0     |                               |
| abap-skill-manager     | ✓       | —      | —     | no config required            |
| abap-unit-test-creator | ✓       | ✓      | 0     |                               |
| abap-vs-reader         | ✓       | ✓      | 0     |                               |
| abap-wiki-doc-creator  | ✓       | ✓      | 0     |                               |

project-config.md: ✓  (TODOs: 0)
```

---

## `status` — Manual mode

```
## Skills Status

Install mode: manual (no submodule — update via abap-skill-manager update)

| Skill                  | SKILL.md | Config | TODOs | Notes                         |
|------------------------|----------|--------|-------|-------------------------------|
| abap-code-review       | ✓        | ✓      | 0     |                               |
| abap-doc-writer        | ✓        | ✓      | 0     |                               |
| abap-unit-test-creator | ✓        | ✓      | 0     |                               |
| abap-vs-reader         | ✓        | ✓      | 0     |                               |
| abap-wiki-doc-creator  | ✓        | ✓      | 0     |                               |

project-config.md: ✓  (TODOs: 0)
```

---

## `validate` — Report

```
## Validation Report

### project-config.md
✓ primary_namespace: /DEMO/
✗ system — still contains TODO

### abap-code-review/configs/
✓ primary_namespace
✓ ddic_naming_rules  (configs/naming.md)
△ auth_check_class_pattern — recommended field missing or TODO (not required)

### abap-doc-writer/configs/
✓ doc_language  (configs/config.md)

### abap-vs-reader/configs/
✓ system_id
✓ virtual_root_segment
✓ virtual_top_package

### abap-wiki-doc-creator/configs/
✓ output_path  (configs/config.md)
✓ primary_namespace  (project-config.md)

### Skill self-tests
— abap-vs-reader: not available — no documented runnable self-test
— abap-code-review: not executed — no authorized test command
— abap-unit-test-creator: not executed — SAP runtime unavailable

---
Summary: 1 validation error; self-tests not executed (not a passing test result).
Fix the flagged fields, then run `abap-skill-manager validate` again.
```

Examples above illustrate layout; never copy their statuses as observed results.
If config checks pass: "All required config fields are filled in." Add actual
self-test results separately, including skipped/unavailable tests and unmet gates.

If config is OK but tests fail, the manager must report a non-zero overall
result and surface the failing test names.

The Config column is complete only when every required owner exists, including
linked files such as abap-vs-reader/configs/system.md. Recommended fields do not
become required merely because the example lists them. Generated stubs/TODOs
must not appear as a valid ready configuration.
