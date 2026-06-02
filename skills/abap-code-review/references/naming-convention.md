# Naming Convention

This guide is a generic baseline, not a project law book. If the workspace or the user provides an explicit naming overlay, that local rule set takes precedence over the examples in this file.

## Principles

- names should reflect role and business meaning
- names should stay consistent within the object and its immediate collaborators
- abbreviations should only be used when their meaning is clear in context

## Generic Baseline Examples

- importing parameters often use `i_`
- exporting parameters often use `e_`
- changing parameters often use `c_`
- returning parameters often use `r_`
- constants often use `co_`
- structures and tables often use `s_`, `t_`, `ts_`, and `tt_`
- object references often use `lo_`, `mo_`, or another locally consistent form

## What To Flag

- returning parameters that obscure intent
- constants without any consistent constant marker in a codebase that otherwise uses one
- ambiguous abbreviations with no domain meaning
- mixed naming schemes inside the same object

## What Not To Do

- do not report a project-specific prefix rule as universal ABAP truth
- do not escalate naming issues above behavioral or contract defects
- do not treat a different but internally consistent local scheme as automatically wrong
