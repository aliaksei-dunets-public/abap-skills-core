# Clean Core

Use this guide when the review touches released API usage, extension boundaries, or upgrade-safe design.

## Core Principles

- Prefer released APIs, released CDS views, and stable extension points.
- Flag direct use of unreleased or restricted internals when policy or platform rules disallow them.
- Prefer upgrade-safe extension patterns over modifications or tightly coupled internals.

## Review Questions

- Does the code depend on a released API or a known stable extension point?
- If it touches internal objects, is that explicitly allowed by the project context?
- Does the change create future upgrade risk by coupling to implementation details?
- Does the data access path bypass a released interface without clear justification?

## Reporting Guidance

When released status cannot be confirmed during the review, state that as a verification gap instead of inventing certainty.
