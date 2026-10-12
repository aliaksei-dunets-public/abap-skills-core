# Config Inventory and Generation

Used by `init` (create) and `update` (append missing fields). Produces
pre-filled config files marked invalid until the user edits them.

**Source:** `$CORE_PATH/skills/<skill>/CONFIG_TEMPLATE.md` (submodule) or
`$SKILLS_PATH/<skill>/CONFIG_TEMPLATE.md` (manual).

## Inventory before writing

Map each declared field to its owner, requirement level and default:

- Required in project-config.md → shared `$SKILLS_PATH/project-config.md`.
- Required in configs/<file>.md → the named skill-local config file.
- Legacy Required Fields → config.md or its explicitly linked owner.
- Path-only headings with a Required table column (for example configs/system.md)
  → yes rows required, no rows optional. A project-config heading without that
  column declares shared context fields.
- Recommended/optional sections retain their level and target. A directory-only
  heading is not a filename; use its explicitly named file or a prose pointer.

Use table names or bullet labels, not example values, as fields. Preserve
existing equivalent labels such as Primary namespace / primary_namespace;
do not create competing copies. Report ambiguous fields/paths instead of
guessing. Follow verified local lazy links inside the selected config layer;
detect cycles, conflicting owners and paths escaping the project.

## Create or enrich

1. Inventory every template even when config.md already exists. Check existing
   owners and valid linked files for a field before adding it.
2. Create missing required owners. Create configs/config.md as the entry point
   when the template declares configs and link additional owners from it.
   The reader's entry point links its configs/system.md. Cross-skill shared
   configs require explicit verified links, not a guessed sibling file.
3. New files get a header. Unfilled required/recommended fields get a comment
   and `field: TODO — hint`, and remain not ready. Shared requirements belong
   in project-config.md, not duplicate skill-local files.
4. Use documented concrete defaults without TODO. Required values without a
   default remain TODO. Copy YAML defaults only into their section's owner and
   only for absent fields; never replace user values.
5. Existing files are append-only. Preserve unknown content, avoid duplicate
   fields/links and report additions. Repeated init/update with unchanged
   templates and complete files must make no change.

Read-only validate uses this same inventory to check presence, nonempty values
and TODO. Do not require optional examples/rule lists or claim a stub is usable.
