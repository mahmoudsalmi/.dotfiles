# Work Brief contract

The Work Brief is the single hand-off format shared by every `sd-*` skill.
Source adapters (`sd-gh-issue`, `sd-ado-ticket`, manual interview) produce it;
`sd-start-work` and `sd-generate-prompt` consume it. Never invent another format.

Location before a worktree exists: `<current-worktree>/.temp/sd/<key>/brief.md`
Location after `sd-start-work`:      `<new-worktree>/.work/<key>/brief.md`

Raw source dumps (issue JSON, ticket tree, comments) live next to it in `source/`.

## Keys

| origin | id example | key        | ref (commits / PR body) |
|--------|------------|------------|-------------------------|
| gh     | 123        | gh-123     | `#123` (`Closes #123` in PR body) |
| ado    | 4567       | ado-4567   | `AB#4567` |
| user   | slug       | user-<slug>| none |

## Format

```md
---
origin: gh | ado | user
id: "123"
key: gh-123
ref: "#123"
title: "Short imperative title"
url: https://...
type: bug | feature | chore | refactor | docs | spike
verdict: relevant | needs-info | obsolete | duplicate | out-of-scope
confidence: high | medium | low
branch: ""            # filled by sd-start-work
worktree: ""          # filled by sd-start-work
---

## Objective
One or two sentences describing the expected OUTCOME (not the activity).

## Context
What the item asks, why it matters, the parts of the system involved
(paths, modules, services), relevant history (linked PRs, previous fixes).

## Findings
Facts with evidence. Every claim cites a source: `path/file.ts:42`, commit sha,
comment author/date, or the tracker field. Separate facts from hypotheses.

## Proposed Solution
Chosen approach, alternatives considered and why rejected, risks.
Split into independent changes when it is too big for one OpenSpec change.

## Acceptance Criteria
- [ ] Observable and testable statements.

## Out of Scope
Things explicitly not done here.

## Open Questions
Things the implementer must ask the user before/while implementing.

## Tracker Update Suggestion
Optional: text to add to the issue/ticket (missing repro steps, findings...).
```

Rules:
- Keep it factual and short; the brief is read by another agent with no prior context.
- Empty sections are written as `None.` rather than removed (stable structure).
