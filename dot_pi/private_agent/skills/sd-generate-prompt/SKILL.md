---
name: sd-generate-prompt
description: Generate an agent-ready PROMPT.md (context, findings, solution, next steps, working agreement with OpenSpec loop) from a Work Brief or by interviewing the user. Use when the user wants a self-contained prompt to hand off a task to another agent/session.
---

# sd-generate-prompt

Render `assets/PROMPT.template.md` into a self-contained prompt that a fresh
agent with **zero prior context** can execute.

## Inputs
- A Work Brief (contract: `../sd-triage-workitem/references/work-brief.md`), or
- nothing → build one by interviewing the user (`origin: user`).
- Output path (default: `.work/<key>/PROMPT.md` in the target worktree).

## Steps

1. **Get a brief.**
   - If a brief path is given, read it.
   - Otherwise interview the user, one question at a time, until you can fill:
     objective, context, acceptance criteria, out of scope. Scout the code
     yourself to fill Findings with evidence; do not ask the user what the code
     can tell you. Save it as `.temp/sd/user-<slug>/brief.md`.
2. **Challenge before rendering.** Check and fix (asking the user if needed):
   - objective is an outcome, measurable via acceptance criteria;
   - every finding has evidence; hypotheses are labeled;
   - solution is split into OpenSpec-sized changes when large;
   - open questions are real blockers, not things you can answer.
3. **Render** the template:
   - `ORIGIN` = `gh` | `az` | `user` (heading uses `az` for ADO); `ID`, `TITLE`, `URL`, `KEY`, `REF`, `BRANCH`, `WORKTREE`, `DATE` (ISO).
   - `PR_LINK_REF`: gh → `Closes #<id>`; ado → `AB#<id>` (GitHub repo) or `--work-items <id>` (ADO repo); user → `n/a`.
   - `NEXT_STEPS`: numbered, one line per OpenSpec change, in execution order.
   - `EXTRA_RULES`: content of `.work/RULES.md` or `.pi/sd-rules.md` in the repo if present, else empty.
   - Unknown values → `None.`; never leave `{{...}}` placeholders.
4. **Write** the file, show the user the Objective + Next Steps and the path.
   Do not execute the prompt yourself.

## Principles
- Self-contained: no "as discussed above"; link files by repo-relative path.
- Specific over generic: name files, commands, owners.
- Short sections; the brief holds the details.
