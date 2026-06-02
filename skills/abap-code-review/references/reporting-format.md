# Reporting Format

Return findings first. Keep the review concise, evidence-based, and severity-ordered.

## Output Order

1. Findings
2. Open questions and assumptions
3. Verification gaps

## Finding Template

Each finding should include:

- severity
- what is wrong
- why it matters
- exact object or file reference and line when available
- any relevant review context such as contract, API status, or affected behavior

## Severity Guidance

- High: likely defect, regression, data integrity issue, transaction risk, or contract break
- Medium: meaningful quality, compliance, or maintainability risk with moderate delivery impact
- Low: small clarity or convention issue with limited delivery risk

## Wording Rules

- Say `not verified` when a check was not executed.
- Say `verification gap` when evidence could not be collected.
- Do not say `passed` unless the output was observed.
- Do not hide assumptions inside findings; move them to the assumptions section.
