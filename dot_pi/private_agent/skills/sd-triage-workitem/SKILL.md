---
name: sd-triage-workitem
description: Analyze a work item (GitHub issue, Azure DevOps ticket tree, or a user request) against the current codebase, decide if it is still relevant, and produce a Work Brief. Use after a source adapter fetched the item, or directly for a free-form user request. Read-only; never writes to trackers.
---

# sd-triage-workitem

Turn a fetched work item into an evidence-based verdict and a **Work Brief**
(contract: `references/work-brief.md`, read it first).

This skill is **read-only** on code and trackers. Tracker writes (close, comment,
edit) belong to the source adapter, always behind explicit user approval.

## Inputs
- `key`, `origin`, `id`, `url`
- Source dump directory: `.temp/sd/<key>/source/` (issue/ticket JSON or markdown)
- For `origin: user`: the user's description (interview them until objective and
  acceptance are clear; ask one focused question at a time).

## Steps

1. **Read the source fully**: title, body, comments, labels/state, children,
   parent, linked PRs/branches. Note who asked what and when.
2. **Scout the code** (delegate to cheap/fast scout subagents when the search
   is broad; do it yourself when it is a couple of greps):
   - search identifiers, error messages, routes, UI labels, file paths from the item;
   - `git log --oneline -S '<term>'` / `git log --grep '<id>'` for prior fixes;
   - existing branches/PRs referencing the id (avoid duplicate work).
3. **Decide a verdict** with confidence and evidence:
   - `relevant` – the problem/need still exists in the code;
   - `needs-info` – cannot conclude; list precisely what is missing;
   - `obsolete` – already fixed/implemented (cite commit/PR/code);
   - `duplicate` – cite the other item;
   - `out-of-scope` – not for this repo/team.
4. **Write the brief** to `.temp/sd/<key>/brief.md` following the contract.
   Ensure `.temp/` is git-ignored first (see `sd-start-work` for the exclude helper).
5. **Report to the user** in this exact shape, then stop and let the caller decide:

```
<key> — <title>
Verdict: <verdict> (<confidence>)
Evidence: 2–5 bullets with file:line / commit / comment refs
Proposal: 1–3 bullets
Effort/Risk: S|M|L / low|medium|high
Suggested tracker update: yes/no (one line why)
```

## Principles
- Evidence over opinion; say "unknown" rather than guess.
- Keep the summary under ~15 lines; details go in the brief.
- Do not start implementing; do not create branches.
