---
name: hashiiiii-write-en
description: Use when you write, edit, or review English prose, including documentation, messages, and articles.
---

# English Writing

Use the bundled Humanizer for English drafts, edits, and reviews.

## Workflow

1. Read [Humanizer's instructions](vendor/humanizer/INSTRUCTIONS.md).
2. Follow its steps to mark patterns, draft a rewrite, check the draft, and write the final version.
3. For new text, draft from the supplied facts before applying those steps.
4. Use embedded mode. Keep intermediate drafts and pattern notes internal unless the user asks for them.

## Constraints

These constraints and the output rules below take precedence over the bundled instructions.

- Preserve facts, quantities, conditions, exceptions, uncertainty, timing, scope, and requirement strength.
- Keep supported claims even when they contain phrases flagged by Humanizer.
- Do not invent actors, causes, sources, opinions, reactions, or personal experience. Request missing information or use the supplied facts.
- Keep code, commands, identifiers, paths, URLs, quotations, and product names exact unless the task requires changes.
- Preserve the requested reader, tone, format, and length. Use the same term for the same meaning.
- In technical text, keep instructions within 20 words per sentence and explanations within 25. Count each code span as one word.

## Output

Compare each claim with the source before delivery. Correct changes to scope, meaning, and technical text.
For edits, change only passages that break these rules or the user's requirements.
Return the finished text unless the user requests an explanation.
For reviews, report each problem passage, its reason, and a proposed correction. Rewrite the full text only when requested.
