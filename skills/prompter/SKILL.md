---
name: prompter
description: Create, improve, audit, and refine prompts for ChatGPT, Claude, Gemini, and other LLMs. Use when Codex needs to turn a rough request into a strong prompt, critique an existing prompt, rewrite prompts for clarity or structure, help a user explore a vague prompt idea, or produce reusable prompt templates and prompt versions.
---

# Prompt Architect

## Overview

Use this skill to transform raw user intent into a production-ready prompt without adding unnecessary complexity. Preserve the original user goal, identify the real prompt task, and adapt the level of structure to the task's risk and ambiguity.

Read [references/universal-prompt.md](references/universal-prompt.md) before producing the final prompt. Treat that file as the source prompt specification and preserve its original wording and structure where practical.

## Core Workflow

1. Detect the primary intent first: `[GENERATE]`, `[IMPROVE]`, `[AUDIT]`, or `[EXPLORE]`.
2. Identify the domain: `[CODE]`, `[QA]`, `[DATA]`, `[CREATIVE]`, `[LEARNING]`, `[AGENT]`, `[META]`, or `[UNIVERSAL]`.
3. Check completeness against role, context, task, input data, output, constraints, and success criteria.
4. Run risk, platform-capability, and research checks before writing the final prompt.
5. Ask clarifying questions only when critical gaps cannot be assumed safely. Keep it to at most 3 questions.
6. Select the lightest prompt structure that will still work reliably.
7. Deliver the final prompt in a fenced Markdown code block in the user's language unless they ask otherwise.

## Skill-Specific Rules

- Prefer the shortest prompt that is still complete and testable.
- Do not assume browsing, tools, memory, file access, or sub-agents unless the target platform is known to support them.
- If the user gives a weak request, explain what is weak before revising it.
- If assumptions are made, state them briefly above the prompt.
- For audits, provide the critique and score first, then the improved prompt.
- For iterative work, label revisions clearly as `v1`, `v2`, `v3` and note what changed.
- If the user asks for a reusable prompt, make the output copy-paste ready with no extra links.
- If the user request is already strong, keep edits minimal and say what changed in a compact summary.

## Output Pattern

Use this response shape unless the user asks for something else:

1. One short line for detected intent and domain.
2. One short assumptions block only if needed.
3. One concise audit block only when the task includes critique.
4. The final prompt in a fenced code block.
5. The calibration line from the reference workflow.
6. The version-loop offer only when the task is complex, uncertain, or experimental.

## Prompt Assembly Notes

- Reuse the section menu from the reference file rather than forcing every section into every prompt.
- Keep anti-patterns only when they materially improve output quality.
- For high-risk topics, require uncertainty disclosure, grounding, and expert review where appropriate.
- For agentic prompts, prefer explicit tool boundaries, fallback handling, and stop conditions.
- For code prompts, prefer architecture before implementation.
- For creative prompts, prefer audience, tone, and CTA only when they matter to the task.

## Trigger Examples

- "Write me a system prompt for a support bot."
- "Improve this prompt for Claude."
- "Audit this prompt and score it."
- "I only have a vague idea for a research assistant prompt."
- "Turn this requirement doc into a reusable ChatGPT prompt."
