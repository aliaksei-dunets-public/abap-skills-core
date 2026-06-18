# Output Examples

Reference outputs for `init`, `status`, and `validate`. Use these as the
canonical layout — keep the column order and headings stable so users can
diff successive runs.

---

## `init` — Summary table (both modes)

| Skill | Wrapper | Config | Action |
|---|---|---|---|
| abap-code-review | ✓ | ✓ | skipped (already present) |
| abap-unit-test-creator | created | created | ✓ |
| abap-vs-reader | created | created | ✓ |
| abap-wiki-doc-creator | created | created | ✓ |
| abap-skill-manager | ✓ | — | skipped (no config required) |

Follow with: "Fill in `$SKILLS_PATH/project-config.md` and each
`configs/config.md`. Run `abap-skill-manager validate` to check for missing
required fields."

---

## `status` — Submodule mode

```
## Skills Status

Install mode: submodule
Core: <current-SHA>  Remote: <remote-SHA>  [UP TO DATE | BEHIND N commits — run: abap-skill-manager update]

| Skill                  | Wrapper | Config | TODOs | Notes                         |
|------------------------|---------|--------|-------|-------------------------------|
| abap-code-review       | ✓       | ✓      | 0     |                               |
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
✗ auth_check_class_pattern — field missing or TODO

### abap-vs-reader/configs/
✓ system_id
✓ cache_base
✓ repotree_package_path

### abap-wiki-doc-creator/configs/
✓ output_path  (configs/config.md)
✓ primary_namespace  (project-config.md)

### Skill self-tests
✓ abap-vs-reader: tests passed (9)
— abap-code-review: no tests
— abap-unit-test-creator: no tests

---
Summary: 2 validation error(s), 0 test failure(s).
Fix the flagged fields, then run `abap-skill-manager validate` again.
```

If all checks **and** all skill self-tests pass, replace the report body with:
"✅ All required fields are filled in and all skill self-tests pass. Ready to use."

If config is OK but tests fail, the manager must report a non-zero overall
result and surface the failing test names.
