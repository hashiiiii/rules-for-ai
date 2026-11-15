---
name: hashiiiii-explain-pr
description: Use when a user asks to understand or explain a pull request's purpose, diff, or relationship to an issue.
---

# Explain a pull request

Explain the reviewed diff in the user's requested language and scope. Work read-only.

## Gather evidence

- Read the title, body, commits, and complete diff. Record the base and head revisions.
- Read related issues linked from the PR metadata or body when available.
- Read surrounding code at those revisions when needed. Check dependency versions before choosing documentation.
- If a source is inaccessible or the diff is incomplete, state that limit.

## Explanation

### Background and purpose

Describe the problem and goal in about ten lines, using fewer when evidence is sparse. Use related issue requirements when available; otherwise use the PR body, commits, and implementation before and after the change. Cite the evidence, label inferred motivations, and identify unknowns.

### Changes by meaning

Explain each independent changed statement, setting, condition, or test case in its own entry. Keep a multiline expression together; split function bodies by statement and branch. Cover scoped code, tests, and documentation. Group equivalent edits and list their locations.

Each entry gives the location (path, line, excerpt, and revision link), syntax meaning, behavior before and after, purpose, and supporting references. Use base locations for removed lines and head locations for added lines. Link related requirements when available. Say when a change has no established link to the goal or leaves a requirement unmet.

Verify documentation URLs, sections, and versions before citing them. Use official references for language, framework, library, or tool behavior, and repository code for project logic. Say when no official reference is available. Separate expected behavior from test or runtime evidence; code inspection alone does not prove deployment or issue closure.
