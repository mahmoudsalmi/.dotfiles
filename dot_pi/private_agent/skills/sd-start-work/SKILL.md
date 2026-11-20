---
name: sd-start-work
description: Turn an approved Work Brief into a ready-to-run workspace - suggest a branch, create a git worktree with wto, write .work/<key>/PROMPT.md via sd-generate-prompt, and open it in a new tmux window. Use after triage when the user decides to start working on an item.
---

# sd-start-work

Script: `scripts/start-work.sh` (run with paths relative to this skill dir).
Requires `wto`, `git`, `jq`; `tmux` optional.

## Inputs
- Brief directory: `.temp/sd/<key>/` containing `brief.md` (+ `source/`).

## Steps

1. **Suggest a branch**: `<type>/<key>-<slug>` — `type` from the brief
   (`fix`, `feat`, `chore`, `refactor`, `docs`, `spike`), slug = 3–5 kebab words,
   whole name ≤ 50 chars. Example: `fix/gh-123-login-timeout`, `feat/ado-4567-export-pdf`.
   Two-part names land in `<repo>/<type>/<name>` with wto.
2. **Show the plan and ask for confirmation** (one message):
   branch, base (`origin/<default>`), worktree location, Objective,
   Next Steps (from the brief), whether to auto-launch an agent in tmux.
   Allow the user to rename the branch.
3. **Create**: `scripts/start-work.sh create <branch> <key> .temp/sd/<key>` → prints the worktree path.
   Note: `wto new` **pushes the new branch to origin** and, inside tmux, creates a
   dedicated tmux session for the worktree (mention both in the plan of step 2).
   Update `branch`/`worktree` in `<path>/.work/<key>/brief.md` frontmatter.
4. **Generate prompt**: use `sd-generate-prompt` with that brief, output
   `<path>/.work/<key>/PROMPT.md`.
5. **Open**: `scripts/start-work.sh open <path> <key> [cmd]`
   - inside tmux → reuse the pane wto created for the worktree, else a new detached window named `<key>`;
   - with auto-launch, cmd = `pi "Read .work/<key>/PROMPT.md and follow it."`;
   - outside tmux → print the `cd` command.
   - pi may stop on the **project trust prompt** in the new worktree: never answer it
     on the user's behalf; tell them to answer it.
6. Report: path, branch, tmux window, prompt path. Notify via `sd-notify` (default)
   only if the user is likely away.

## Optional session handoff
If the user also wants notes that survive the worktree, use `sd-work-session` for that separate request. Link the worktree and brief from the session README; do not move `.work/<key>/` or change the generated prompt path. Starting a worktree alone does not require session configuration.

## Rules
- Never create the worktree without confirmation.
- If a branch/worktree for this key already exists (`wto status --format json`),
  propose reusing it instead of creating a new one.
- `.work/` and `.temp/` are ignored through `.git/info/exclude`
  (`start-work.sh ignore`), never by editing the tracked `.gitignore`.
