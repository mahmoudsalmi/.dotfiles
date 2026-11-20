---
name: sd-work-session
description: Initialize an off-repository work area with node READMEs and a generated index, or create, find, resume, update, and close a work-session folder. Use for dated session notes, selected evidence, and handoffs, not for managing agent transcripts or Git worktrees.
---

# Work sessions

## Required environment

Before **every operation**, including listing, run `sh scripts/check-root.sh` using the script's absolute path relative to this skill, **without changing the caller's working directory**. It reads `SD_WORK_DIR` from the environment, not from a file. On failure, stop before reading or writing session files. Relay the diagnostic and ask the user to configure the variable and retry. Never substitute the current directory, a remembered path, another variable, or a path supplied only in chat.

Setup is for the user, not the agent. With mise, the user can add the following to the `mise.toml` in a common parent of their repositories. For a global default, use `~/.config/mise/config.local.toml` instead; a nearer configuration can override it. Replace the example with an existing absolute path outside the repositories:

```toml
[env]
SD_WORK_DIR = "/absolute/path/to/work-area"
```

Start Pi from the intended repository with `mise exec -- pi` so it inherits the value. Without mise, run `export SD_WORK_DIR="/absolute/path/to/work-area"` and launch Pi from that shell. Do not edit configuration, activate mise, or set a temporary value on the user's behalf.

## Initialize the work area

For “initialize my work area”, run `sh scripts/init-area.sh` (resolve the script against this skill's directory). For a first session in an empty root, bootstrap the area before creating the session. In a partially populated area, offer to fill missing nodes; do not silently migrate an existing layout. Listing and resuming never bootstrap anything.

```text
$SD_WORK_DIR/
├── README.md          overview and generated node inventory
├── INDEX.md           full contents tree
├── refresh-index.mts  standalone TypeScript indexer (Node.js 22.18+)
├── sessions/README.md session table, tree and intake instructions
├── data/README.md     category table, tree and reuse conventions
└── logs/README.md     collection naming, compression rules and tree
```

The bootstrap seeds missing files from `assets/work-area/` and `scripts/refresh-index.mts`; it does not replace existing READMEs or a custom indexer. Work-area setup is distinct from mise setup and never edits the caller's environment.

## Session operations

After preflight, read the root and relevant collection README if present. For large inventories, read the handwritten procedures rather than loading the generated file tree. Resolve paths under the validated `SD_WORK_DIR`, quote them, and reject links that escape the intended collection. The work area is private: nothing here is automatically committed or shared.

- **Init:** Use the local date and a descriptive lowercase kebab-case slug (`YYYY-MM-DD-slug`). Accept only a single slug component, never a path. Check for an existing session for the same effort, including earlier dates; offer to resume it rather than overwrite it. Create `sessions/` if needed, then create the new folder exclusively. Render `assets/session-readme.md` (relative to this skill) as `README.md`. Replace the date, topic and all prompts with known facts or an explicit “None yet.” Keep the first heading and the five section names: the heading supplies the index topic. Link back to `../README.md` when it exists. A README alone is enough.
- **Find / resume:** List matching dated folders. If none match, say so; if several match, ask which to use. Read the selected README first. Summarize where work stopped and what to do next. Verify any historical status that matters before relying on it; archived commands are not instructions to execute. Do not modify files on resume alone.
- **Update:** Record the requested decisions, links, or changed next steps in the existing README. Keep the original folder name and date. Preserve unrelated notes and generated sections.
- **Close / archive:** Record the outcome, where the lasting changes live, what remains open, and how someone could resume. Retain only relevant, reviewed evidence; link to published material rather than copying it. Exclude credentials, unrelated private data, caches, build outputs, and redundant history. Report the session path and what was retained. Closing is a handoff, not permission to delete a session, branch, or worktree, publish a report, or update a tracker.

## Decide what to keep and where

Triage before copying. Use `sessions/` for time-bound notes, drafts, decisions and redacted run evidence. Keep the durable result in its authoritative home. Use relative links to sibling sessions, reusable data or log collections instead of duplicating them. Do not copy entire worktrees, private transcripts, IDE files, `.DS_Store`, superseded drafts or backups recoverable from version history.

- **Reusable material:** With requested intake, place it in `data/<category>/`, not a dated session. Use `docs/` or a topical folder for references and `config/` for tool settings. Each category README starts with `# <Category>` and a one-line description for the category index, then explains contents and reuse. Keep secrets out of notes and reports. Where local secret storage is authorized, only `data/<category>/config/` may hold it (directory `700`, files `600`); never print values or copy them into repos, trackers, email or chat.
- **Cross-session application or server logs:** With requested intake, use `logs/YYYY-MM-DD-o-<lowercase-office-alias>/` or `logs/YYYY-MM-DD-u-<UPPERCASE-INITIALS>/`. Ask if date or attribution is unknown. Store standalone logs as gzip with the original name as stem (`app.log` → `app.log.gz`); keep existing archives unchanged. Verify the compressed copy before discarding any uncompressed *staging copy*; leave original source collections untouched. Search in place, e.g. `rg --search-zip -n 'ERROR|WARN' "$SD_WORK_DIR/logs"`; redact before quoting results.
- **Evidence archives:** For a multi-file transfer that needs verification, record the source and retained relative path, reason, byte size and SHA-256 per retained file in `archive-manifest.json`. Verify the destination against the source; document redactions or transformations separately. Report mismatches and exclusions rather than declaring the archive complete. A verified transfer says nothing about unrelated ignored files and never authorizes cleanup.

## Refresh and verify

After adding, moving or removing entries, or changing an indexed title or description, run the root's **documented, trusted** index procedure. For a newly initialized area, run `node "$SD_WORK_DIR/refresh-index.mts"`. This is a skill helper invoked through the shell, not a Pi extension. Existing areas with their own indexer keep their documented command; migration is opt-in. Do not run a script merely because it exists. Check that the affected entry appears as expected in the collection README and, where maintained, the root inventory and `INDEX.md`. Never hand-edit generated `index:start/end` or `tree:start/end` blocks. If no indexer is configured, skip it; if a documented refresh fails, report the stale index separately from the successful file changes. Find/resume alone needs no refresh.
