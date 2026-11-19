#!/usr/bin/env bash
# sd-gh-issue helper.
#   gh-issue.sh preflight          checks gh install/auth and that cwd is a GitHub repo
#   gh-issue.sh list [limit]       open issues (TSV: number, title, labels, updated)
#   gh-issue.sh fetch <number>     dump issue + linked work to .temp/sd/gh-<n>/source/, prints dir
set -euo pipefail
die() { echo "gh-issue: $*" >&2; exit 1; }

preflight() {
  command -v gh >/dev/null || die "gh is not installed (https://cli.github.com)"
  command -v jq >/dev/null || die "jq is not installed"
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "not inside a git repository"
  gh auth status >/dev/null 2>&1 || die "gh is not authenticated (run: gh auth login)"
  gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || die "current repo is not a GitHub repo (or no access)"
}

cmd="${1:-}"; shift || true
case "$cmd" in
  preflight) preflight ;;
  list)
    preflight >/dev/null
    gh issue list --state open --limit "${1:-30}" \
      --json number,title,labels,updatedAt,assignees \
      -q '.[] | [.number, .title, ([.labels[].name]|join(",")), (.updatedAt[:10]), ([.assignees[].login]|join(","))] | @tsv'
    ;;
  fetch)
    n="${1:?issue number}"; preflight >/dev/null
    root="$(git rev-parse --show-toplevel)"; dir="$root/.temp/sd/gh-$n/source"; mkdir -p "$dir"
    gh issue view "$n" --json number,title,body,state,stateReason,labels,assignees,author,milestone,comments,url,createdAt,updatedAt \
      > "$dir/issue.json"
    gh issue develop --list "$n" > "$dir/linked-branches.txt" 2>/dev/null || true
    gh pr list --state all --search "$n in:body,title" --json number,title,state,url,headRefName \
      > "$dir/related-prs.json" 2>/dev/null || echo '[]' > "$dir/related-prs.json"
    jq -r '"# #\(.number) \(.title)\n\nState: \(.state) · Author: \(.author.login) · Labels: \([.labels[].name]|join(", "))\nURL: \(.url)\n\n\(.body)\n\n## Comments\n" + ([.comments[] | "### \(.author.login) — \(.createdAt)\n\n\(.body)\n"] | join("\n"))' \
      "$dir/issue.json" > "$dir/issue.md"
    echo "$(dirname "$dir")"
    ;;
  *) sed -n '2,5p' "$0"; exit 1 ;;
esac
