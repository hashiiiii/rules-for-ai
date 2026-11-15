---
name: hashiiiii-write-en
description: Use when you write, edit, or review English prose, including documentation, messages, and articles.
---

# English writing

Write for the reader's task. Use the pinned [Harper](https://writewithharper.com/) grammar checker to check the draft locally.

## Workflow

1. Identify the reader, purpose, tone, and requested English dialect from the task and surrounding text. Retain the source for comparison.
2. Draft from the supplied facts. Lead with the point the reader needs. Give each paragraph one job and connect its sentences.
3. Revise for natural English: check articles, agreement, tense, prepositions, word choice, and sentence flow. Prefer concrete verbs and ordinary words. Split sentences when this helps the reader; keep related conditions together.
4. Run `node <skill-dir>/scripts/check.mjs <absolute-draft-path>` before delivery. Replace `<skill-dir>` with this skill's absolute directory. Markdown files use Harper's Markdown parser; other files use plain text. For another dialect, pass `--dialect British`, `Australian`, `Canadian`, or `Indian` before the path. The default is American English.
5. Review each diagnostic in context. Apply a suggestion only when it improves the text and preserves the source's meaning. Quoted logs, identifiers, and deliberate wording can legitimately trigger findings.
6. Compare the draft with the source, then read it as a whole. Check grammar, flow, repetition, missing conditions, and changes to certainty or timing. Rerun the checker after edits; deliver the exact checked text.

The checker requires Node.js 20 or later and npm 8.3 or later. On first use, run `node <skill-dir>/scripts/check.mjs setup`.  
Setup uses npm to install the locked packages without lifecycle scripts in a user-owned cache, outside the project and skill directory.  
Checks then run offline; the draft is never sent to an external service. See [runtime dependencies](DEPENDENCIES.md) for cache and update details.

Check chat prose through a temporary file. Remove only temporary files created for this task.  
If Node.js, npm, installation, or checking is unavailable, review manually and state which check could not run and why.

## Constraints

- Preserve facts, quantities, conditions, exceptions, uncertainty, timing, scope, and requirement strength.
- Do not invent actors, causes, sources, opinions, reactions, or personal experience. Request missing information or use the supplied facts.
- Keep code, commands, identifiers, paths, URLs, quotations, and product names exact unless the task requires changes.
- Keep errors inside quoted logs exact, including their punctuation. Put any added sentence punctuation outside the quotation.
- Preserve the requested reader, tone, format, and length. Use the same term for the same meaning.
- Preserve the writer's voice. Remove filler and repeated explanations without adding opinions or making every sentence the same length.

## Output

For edits, change only passages that break these rules or the user's requirements.  
Return the finished text unless the user requests an explanation. Keep drafts and diagnostic notes internal.  
For reviews, report each problem passage, its reason, and a proposed correction. Rewrite the full text only when requested.  
Harper reports suggestions, not a quality score or proof of factual accuracy. Never claim a check ran when it did not.
