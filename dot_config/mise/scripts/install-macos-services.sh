#!/bin/sh
# Install the macOS launchd limit daemons (maxfiles, maxproc) as system services.
# Needs administrator rights: sudo is requested for each system change.
set -eu

if [ "$(uname -s)" != Darwin ]; then
    printf '%s\n' 'macOS launchd services are only available on Darwin.' >&2
    exit 1
fi

src="${XDG_CONFIG_HOME:-$HOME/.config}/mise/macos-services"
dst=/Library/LaunchDaemons

for plist in "$src"/*.plist; do
    file=$(basename "$plist")
    name=${file%.plist}
    sudo cp "$plist" "$dst/$file"
    sudo chown root:wheel "$dst/$file"
    # Unload first so reruns pick up plist changes; ignore "not loaded" errors.
    sudo launchctl bootout "system/$name" 2>/dev/null || :
    sudo launchctl load -w "$dst/$file"
    sudo launchctl print "system/$name" >/dev/null
    printf 'Installed %s\n' "$name"
done
