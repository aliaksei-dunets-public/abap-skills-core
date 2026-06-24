# Skill Registry — Maintenance

For the agent working in `abap-skills-core`. Apply whenever a skill is created
or a skill's config contract changes.

---

## When a new skill is added to `abap-skills-core`

A new skill exists when a new subdirectory appears under `skills/` containing
a `SKILL.md`. Update `skills/abap-skill-manager/references/output-examples.md`
in four places:

1. **`init` summary table** — add row:
   `| <skill-name> | created | generated | ✓ |`
   If the skill has no `CONFIG_TEMPLATE.md`, use `—` in the Config column and
   note "no config required".

2. **`status` submodule table** — add row (alphabetical):
   `| <skill-name> | ✓ | ✓ | 0 | |`
   If the skill has no config, use `—` in Config/TODOs and set Notes to
   "no config required".

3. **`status` manual table** — add the same row to the manual-mode table.

4. **`validate` example report** — add a section:
   ```
   ### <skill-name>/configs/
   ✓ <required_field_1>
   ✓ <required_field_2>
   ```
   If the skill has no `CONFIG_TEMPLATE.md`, omit this section.

---

## When an existing skill's config contract changes

A contract changes when `CONFIG_TEMPLATE.md` gains, loses, or renames a field
under any `## Required ...` heading (typical forms:
`## Required in `project-config.md``, `## Required in `configs/<file>.md``,
or the legacy `## Required Fields ...`).

1. **Field added** — append to the relevant `### <skill>/configs/` block in
   the `validate` example. If the field belongs to `project-config.md`, add
   it under `### project-config.md` instead.
2. **Field removed** — delete the corresponding line.
3. **Field renamed** — update the field name.
4. **`project-config.md` template changes** — also update the standard
   template in `references/templates.md`.

After any change, re-read the updated `CONFIG_TEMPLATE.md` and verify the
validate example matches before saving.

Changes outside `## Required ...` headings usually do not require manager updates by themselves. Examples:

- new optional category codes such as `ARCH` or `TESTSUG`
- revised output semantics in another skill
- new recommended fields or explanatory notes

For those cases, update `abap-skill-manager` only if one of these is true:

1. the standard `project-config.md` template changed
2. the `validate` command must enforce a new required field
3. manager-owned examples or maintenance notes became misleading

---

## Source Evidence Convention

When creating or updating skills, enforce this architecture rule:

- skills may declare which source and related context they need
- skills must not prescribe retrieval chains, tool probe order, or platform-specific fallback flows
- missing evidence should be handled by one scoped unblock question, a verification-gap note, or an explicit stop

Treat new procedural source-reading logic in a skill as a maintenance issue and remove it before finishing the update.

---

## Checklist (apply for every skill change)

- [ ] `init` summary table updated
- [ ] `status` submodule table updated
- [ ] `status` manual table updated
- [ ] `validate` example report updated
- [ ] `project-config.md` template updated (only if the skill adds a shared field)
