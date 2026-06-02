# RAP Review

Use this guide when the review touches RAP behavior definitions, behavior implementations, handlers, savers, projections, actions, determinations, or validations.

## Contract Checks

Review whether:

- `%control` is used consistently for changed fields
- EML operations match the intended behavior contract
- validations reject invalid state early enough
- determinations do not silently overwrite user intent without contract support
- reported and failed messages are propagated coherently

## Handler And Saver Risks

Flag issues such as:

- missing message propagation from validation or action logic
- save-sequence assumptions that can create inconsistent state
- handler logic that mixes responsibilities in a way that hides contract boundaries

## Severity Guidance

- High: broken `%control`, incorrect EML semantics, or lost error propagation
- Medium: unclear contract alignment or risky save ordering
- Low: readability issues that do not change contract behavior
