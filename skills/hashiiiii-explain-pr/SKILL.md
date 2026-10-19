---
name: hashiiiii-explain-pr
description: Use when a user asks to understand or explain a pull request's purpose, diff, or relationship to an issue.
---

# Explain a pull request

Explain the reviewed diff in the user's requested language and scope. Work read-only.

## Gather evidence

- Read the PR title, body, commits, and complete diff. Record the reviewed base and head revisions.
- Find related issues in PR metadata and body links, then read them. A related issue is optional.
- If a source is inaccessible or the diff is incomplete, state the limit and explain the available material.
- Read surrounding code at those revisions when needed to explain behavior. Check dependency versions when choosing documentation.

## Explanation

### Background and purpose

Describe the background, problem, and goal in about ten lines. Use fewer lines when the evidence is sparse.

- With related issues, explain their requirements and how they relate to the PR's stated purpose.
- Without related issues, use the PR body, commit messages, and implementation before and after the change.
- Cite the sources for the stated purpose. Label inferred motivations as inferences and missing information as unknown.

### Changes by meaning

Give each independent changed statement, setting, condition, or test case its own entry.
Keep a single expression spanning several lines together. Split function bodies into independent statements and branches.
For example, three added test cases require three entries.
Cover every change within the requested scope, including tests and documentation.
Group repeated equivalent edits and list their affected locations.

For each entry, use these fields:

- Location: file path, line numbers, and a short excerpt of the changed lines. Link to the reviewed revision.
- Behavior: explain what the syntax means and what changes before and after the PR.
- Purpose: explain its contribution to the PR's goal. With related issues, identify the corresponding requirement and link it.
- References: link official documentation beside the syntax or behavior it supports.

Use base-revision locations for removed code and head-revision locations for added code.
Say when a unit has no established relationship to the stated purpose or leaves a requirement unmet.

Open documentation pages and verify their URLs, relevant sections, and applicable versions before citing them.
Choose references for the actual language, framework, library, or tool involved.
For project-specific logic, cite repository code. If an official reference is unavailable, say so.

Separate expected behavior from test or runtime evidence.
Reading code alone does not prove successful deployment or issue closure.
