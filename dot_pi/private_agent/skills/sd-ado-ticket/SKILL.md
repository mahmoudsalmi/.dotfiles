---
name: sd-ado-ticket
description: Work on an Azure DevOps work item end-to-end - fetch the ticket with its parent and full child sub-tree, triage it against the code, optionally close or comment it, and start a dedicated worktree with a generated PROMPT.md. Use when the user gives an ADO ticket id, AB#id, or a dev.azure.com work item URL.
---

# sd-ado-ticket

Source adapter for Azure DevOps Boards. Same flow as `sd-gh-issue`; composes
`sd-triage-workitem` → (`sd-start-work` → `sd-generate-prompt`), plus `sd-notify`.

Set `SD_ADO_ORG` (organization URL) and `SD_ADO_PROJECT` (project name) in the environment before running the script; neither has a built-in default.
Script: `scripts/ado-ticket.sh` (`preflight` | `fetch <id>`).

## Steps

1. **Preflight**: `ado-ticket.sh preflight`. On failure, report the exact fix
   (`az login`, `az extension add -n azure-devops`, `AZURE_DEVOPS_EXT_PAT`) and stop.
2. **Ticket id is required** — no listing. If missing, ask for it
   (accept `4567`, `AB#4567`, or a work item URL).
3. **Fetch**: `ado-ticket.sh fetch <id>` → `.temp/sd/ado-<id>/source/`:
   `tree.md` (readable root + all descendants + comments), `tree.json`
   (flat list with depth, state, non-hierarchy links such as PRs/commits),
   `parent.json` (context only), `items/*.json` (raw).
4. **Triage** with `sd-triage-workitem` (`key: ado-<id>`, `ref: AB#<id>`, `origin: ado`):
   - Analyze the whole sub-tree, not only the root: which children are done,
     still open, obsolete; the brief's Next Steps should map to open children.
   - Use the parent only to understand intent; do not expand scope to it.
5. **Decide with the user** (same options as `sd-gh-issue`): start work,
   comment with missing info / findings, or close.
6. **Tracker writes** (only after showing the exact text and getting a yes):
   - comment: `az boards work-item update --id <id> --discussion "<text>" --org <org>`;
   - close: ask which state the process allows (e.g. `Closed`, `Removed`, `Done`) and the reason, then
     `az boards work-item update --id <id> --state "<state>" --discussion "<why + evidence>" --org <org>`.
   Never change children's state unless the user asks per item.

## PR linking
- Code on GitHub (check `git remote -v`): put `AB#<id>` in commits and PR body
  (requires the Azure Boards GitHub app on the repo; tell the user if links don't appear).
- Code on Azure Repos: `az repos pr create ... --work-items <id>`.
