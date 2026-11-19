#!/usr/bin/env bash
# sd-ado-ticket helper.
#   ado-ticket.sh preflight          checks az + azure-devops extension + access to org/project
#   ado-ticket.sh fetch <id>         dump ticket, its parent and full child sub-tree (+comments)
#                                    to .temp/sd/ado-<id>/source/, prints the brief dir
# Env: SD_ADO_ORG and SD_ADO_PROJECT (required), SD_ADO_MAX_ITEMS (default 200).
# Auth: `az login` or AZURE_DEVOPS_EXT_PAT.
set -euo pipefail
ORG="${SD_ADO_ORG:-}"
PROJECT="${SD_ADO_PROJECT:-}"
MAX="${SD_ADO_MAX_ITEMS:-200}"
die() { echo "ado-ticket: $*" >&2; exit 1; }

preflight() {
  [[ -n "$ORG" ]] || die "set SD_ADO_ORG to your Azure DevOps organization URL"
  [[ -n "$PROJECT" ]] || die "set SD_ADO_PROJECT to your Azure DevOps project name"
  command -v az >/dev/null || die "az is not installed"
  command -v jq >/dev/null || die "jq is not installed"
  az extension show -n azure-devops >/dev/null 2>&1 || die "missing extension: az extension add -n azure-devops"
  az devops project show --project "$PROJECT" --org "$ORG" -o none 2>/dev/null \
    || die "cannot access $ORG/$PROJECT (run: az login, or export AZURE_DEVOPS_EXT_PAT)"
  echo "$ORG/$PROJECT"
}

html2md() { if command -v pandoc >/dev/null; then pandoc -f html -t gfm --wrap=none 2>/dev/null; else sed -e 's/<[^>]*>//g'; fi; }

show() { az boards work-item show --id "$1" --expand relations --org "$ORG" -o json; }
comments() {
  az devops invoke --area wit --resource comments --org "$ORG" \
    --route-parameters project="$PROJECT" workItemId="$1" \
    --api-version 7.1-preview.4 -o json 2>/dev/null || echo '{"comments":[]}'
}
rel_ids() { jq -r --arg r "$2" '.relations // [] | .[] | select(.rel==$r) | .url | split("/") | last' "$1"; }

render() { # $1 json file, $2 depth
  local f="$1" d="$2" pad; pad="$(printf '#%.0s' $(seq 1 $((d+2))))"
  jq -r --arg pad "$pad" '.fields as $f |
    "\($pad) \($f["System.WorkItemType"]) \(.id): \($f["System.Title"])\n\n" +
    "State: \($f["System.State"]) · Assigned: \($f["System.AssignedTo"].displayName // "-") · Area: \($f["System.AreaPath"]) · Iteration: \($f["System.IterationPath"]) · Tags: \($f["System.Tags"] // "-")\n"' "$f"
  for field in System.Description Microsoft.VSTS.TCM.ReproSteps Microsoft.VSTS.Common.AcceptanceCriteria; do
    local v; v="$(jq -r --arg k "$field" '.fields[$k] // empty' "$f")"
    [[ -n "$v" ]] && printf '\n**%s**\n\n%s\n' "${field##*.}" "$(printf '%s' "$v" | html2md)"
  done
  local cf="${f%.json}.comments.json"
  if [[ -s "$cf" ]] && [[ "$(jq '.comments|length' "$cf")" -gt 0 ]]; then
    printf '\n**Comments**\n'
    jq -r '.comments[] | "\n- \(.createdBy.displayName) — \(.createdDate[:10])\n\n\(.text)"' "$cf" | html2md
  fi
  echo
}

cmd="${1:-}"; shift || true
case "$cmd" in
  preflight) preflight ;;
  fetch)
    id="${1:?ticket id}"; preflight >/dev/null
    root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
    dir="$root/.temp/sd/ado-$id/source"; mkdir -p "$dir/items"
    show "$id" > "$dir/items/$id.json"; comments "$id" > "$dir/items/$id.comments.json"

    # parent (context only, one level)
    parent="$(rel_ids "$dir/items/$id.json" System.LinkTypes.Hierarchy-Reverse | head -1)"
    [[ -n "$parent" ]] && show "$parent" > "$dir/parent.json"

    # BFS over children
    queue=("$id:0"); order=(); count=0
    while ((${#queue[@]})); do
      entry="${queue[0]}"; queue=("${queue[@]:1}")
      cur="${entry%%:*}"; depth="${entry##*:}"; order+=("$entry")
      for c in $(rel_ids "$dir/items/$cur.json" System.LinkTypes.Hierarchy-Forward); do
        ((++count > MAX)) && { echo "ado-ticket: truncated at $MAX items" >&2; break 2; }
        show "$c" > "$dir/items/$c.json"; comments "$c" > "$dir/items/$c.comments.json"
        queue+=("$c:$((depth+1))")
      done
    done

    # tree.json (flat list with depth/parent) + tree.md
    for e in "${order[@]}"; do
      jq -c --argjson d "${e##*:}" '{id, depth:$d, type:.fields["System.WorkItemType"], title:.fields["System.Title"],
        state:.fields["System.State"], parent:.fields["System.Parent"],
        links:[.relations // [] | .[] | select(.rel|test("Hierarchy")|not) | {rel, url, name:.attributes.name}]}' "$dir/items/${e%%:*}.json"
    done | jq -s . > "$dir/tree.json"
    {
      echo "# ADO $id — $ORG/$PROJECT/_workitems/edit/$id"; echo
      [[ -f "$dir/parent.json" ]] && jq -r '"Parent: \(.fields["System.WorkItemType"]) \(.id) — \(.fields["System.Title"]) [\(.fields["System.State"])]\n"' "$dir/parent.json"
      for e in "${order[@]}"; do render "$dir/items/${e%%:*}.json" "${e##*:}"; done
    } > "$dir/tree.md"
    echo "$(dirname "$dir")"
    ;;
  *) sed -n '2,7p' "$0"; exit 1 ;;
esac
