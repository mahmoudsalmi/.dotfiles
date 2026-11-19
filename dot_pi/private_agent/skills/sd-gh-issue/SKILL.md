---
name: sd-gh-issue
description: Work on a GitHub issue of the current repo end-to-end - pick or fetch the issue, triage it against the code, optionally close or update it, and start a dedicated worktree with a generated PROMPT.md. Use when the user mentions a GitHub issue (#123, issue URL) or wants to pick an open issue to work on.
---

# sd-gh-issue

Source adapter for GitHub. Composes: `sd-triage-workitem` → (`sd-start-work` →
`sd-generate-prompt`), with `sd-notify` when relevant.

Script: `scripts/gh-issue.sh` (`preflight` | `list` | `fetch <n>`).

## Steps

1. **Preflight**: `gh-issue.sh preflight`. On failure, report the exact reason and stop
   (gh missing, not authenticated, not a GitHub repo).
2. **Select the issue**
   - Number or URL given → use it.
   - Otherwise `gh-issue.sh list` and show a compact numbered table
     (#, title, labels, updated, assignee); ask the user to pick one.
3. **Fetch**: `gh-issue.sh fetch <n>` → `.temp/sd/gh-<n>/source/` (issue.json, issue.md,
   linked branches, related PRs). If the issue is closed, say so and ask whether to continue.
4. **Triage** with `sd-triage-workitem` (`key: gh-<n>`, `ref: #<n>`, `origin: gh`).
5. **Decide with the user** based on the verdict (one question, explicit options):
   - `relevant` → "Start working on it?"  
     - yes → `sd-start-work` with `.temp/sd/gh-<n>/`.
     - no → if the brief has a *Tracker Update Suggestion*, offer to post it.
   - `needs-info` → offer to post a comment listing the missing information.
   - `obsolete` / `duplicate` / `out-of-scope` → offer to close with a comment citing the evidence.
6. **Tracker writes** (only after showing the exact text and getting a yes):
   - comment: `gh issue comment <n> --body-file <file>` (preferred, non-destructive);
   - edit body: `gh issue edit <n> --body-file <file>` (only if the user asks to rewrite);
   - close: `gh issue close <n> --reason "not planned"|"completed" --comment "<text>"`
     (`duplicate` → reason `not planned` + `Duplicate of #<m>`).
   Write the text to `.temp/sd/gh-<n>/` first so it is reviewable.

## Rules
- Never write to GitHub without explicit approval of the exact content.
- If an open PR/branch already targets the issue, surface it before proposing new work.
