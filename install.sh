#!/usr/bin/env bash
# Copies fleet's worker templates into hc's templates folder, where they are
# this machine's to edit, such as a command: line naming its models. Rerun
# after the repo's templates change: a copy you have not edited is replaced,
# and one you have gets the repo's changes merged in (git merge-file), against
# the version this install last copied, kept in .fleet/. install.ps1 is the
# Windows version.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/herdr-core/templates"
path="$HOME/.config/herdr-core/templates"
base="$path/.fleet"

# An earlier install linked the whole folder to the repo.
[ ! -L "$path" ] || rm "$path"
if [ -e "$path" ] && [ ! -d "$base" ]; then
    echo "$path exists and was not written by fleet; move it aside and rerun." >&2
    exit 1
fi
mkdir -p "$base"

conflicts=0
for src in "$repo"/*.md; do
    name=$(basename "$src")
    dest="$path/$name"
    if [ ! -e "$dest" ] || [ ! -e "$base/$name" ]; then
        cp "$src" "$dest"
        echo "added    $dest"
    elif cmp -s "$src" "$base/$name"; then
        echo "ok       $dest"
        continue
    elif cmp -s "$dest" "$base/$name"; then
        cp "$src" "$dest"
        echo "updated  $dest"
    elif git merge-file -L "this machine" -L "last install" -L "repo" "$dest" "$base/$name" "$src"; then
        echo "merged   $dest"
    else
        echo "CONFLICT $dest: resolve the <<<<<<< markers by hand" >&2
        conflicts=1
    fi
    cp "$src" "$base/$name"
done

# Templates the repo no longer has.
for old in "$base"/*.md; do
    [ -e "$old" ] || continue
    name=$(basename "$old")
    [ ! -e "$repo/$name" ] || continue
    if cmp -s "$path/$name" "$old"; then
        rm -f "$path/$name"
        echo "removed  $path/$name"
    elif [ -e "$path/$name" ]; then
        echo "kept     $path/$name: the repo dropped it, but it was edited here; delete it if unneeded"
    fi
    rm "$old"
done
exit $conflicts
