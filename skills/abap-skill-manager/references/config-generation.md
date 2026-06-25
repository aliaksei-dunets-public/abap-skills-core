# Config Generation Algorithm

Used by `init` (create) and `update` (append missing fields). Produces
pre-filled config files marked invalid until the user edits them.

**Source:** `$CORE_PATH/skills/<skill>/CONFIG_TEMPLATE.md` (submodule) or
`$SKILLS_PATH/<skill>/CONFIG_TEMPLATE.md` (manual).

**Steps:**

1. Write header:
   ```
   # <skill-name> — Project Config
   # ⚠ NOT VALID — review all TODO values before using this skill.
   ```

2. `## Required in \`configs/config.md\`` or `## Required Fields` section:
   - Write `## Required Fields` heading.
   - Each field: comment line (`# <description>`) + value line (`<field>: TODO — <hint or "fill in">`).

3. `## Recommended Fields` section (if present):
   - Write `## Recommended Fields` heading.
   - Each field: same pattern — comment + `<field>: TODO — <hint>`.

4. Fenced ` ```yaml ` block with concrete defaults: copy verbatim under `## Defaults` (no TODO needed).

5. All other sections (Category Control, Rule Suppression, Output Mode, etc.):
   write section heading + one-line reference comment pointing to template; do not duplicate content.

All Required and Recommended values must start with `TODO`.
