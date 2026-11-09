#!/usr/bin/env bash
# Links fleet's worker templates into hc's config folder. A link, not a copy,
# so edits in this repo apply at once. install.ps1 is the Windows version.
set -euo pipefail

target="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/herdr-core/templates"
path="$HOME/.config/herdr-core/templates"

if [ -L "$path" ]; then
    if [ "$(readlink "$path")" = "$target" ]; then
        echo "ok      $path"
        exit 0
    fi
    rm "$path"
elif [ -e "$path" ]; then
    echo "$path exists and is not a link; move it aside and rerun." >&2
    exit 1
fi
mkdir -p "$(dirname "$path")"
ln -s "$target" "$path"
echo "linked  $path -> $target"
