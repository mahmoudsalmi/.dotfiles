#!/bin/sh
# Bootstrap only missing files in the configured work area. Never run local code.
set -eu
umask 077
here=$(CDPATH='' cd -P "$(dirname "$0")" && pwd)
root=$(sh "$here/check-root.sh")
if [ -e "$root/refresh-index.py" ] || [ -L "$root/refresh-index.py" ]; then
    echo 'Existing Python indexer detected. No changes made; keep the documented workflow or request a migration.' >&2
    exit 1
fi
if ! command -v node >/dev/null || ! node --check "$here/refresh-index.mts" >/dev/null 2>&1; then
    echo 'Node.js with native TypeScript support (22.18+ recommended) is required for indexing.' >&2; exit 1
fi
for node in sessions data logs; do
    if [ -L "$root/$node" ] || { [ -e "$root/$node" ] && [ ! -d "$root/$node" ]; }; then
        echo "Cannot initialize: $node must be a real directory." >&2; exit 1
    fi
done
for node in sessions data logs; do mkdir -p "$root/$node"; done
seed() {
    if [ -e "$2" ] || [ -L "$2" ]; then printf 'Preserved: %s\n' "$2"; return; fi
    # noclobber also protects a regular file created after the existence check.
    (set -C; cat "$1" > "$2")
}
for file in README.md INDEX.md sessions/README.md data/README.md logs/README.md; do
    seed "$here/../assets/work-area/$file" "$root/$file"
done
seed "$here/refresh-index.mts" "$root/refresh-index.mts"
if [ ! -L "$root/refresh-index.mts" ] && [ -f "$root/refresh-index.mts" ] && cmp -s "$here/refresh-index.mts" "$root/refresh-index.mts"; then
    node "$here/refresh-index.mts"
else
    echo 'Existing indexer preserved; use the trusted refresh procedure documented for this area.'
fi
