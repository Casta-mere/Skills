#!/bin/bash

SKILLS_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$HOME/.claude/commands"

mkdir -p "$TARGET"

# If target is currently a symlink to this repo, replace it with a real directory
if [ -L "$TARGET" ]; then
  echo "Removing old symlink: $TARGET → $(readlink "$TARGET")"
  rm "$TARGET"
  mkdir -p "$TARGET"
fi

# Symlink each .md skill file into the commands directory
for file in "$SKILLS_DIR"/*.md; do
  [ -f "$file" ] || continue
  name="$(basename "$file")"
  # Skip non-skill files
  [ "$name" = "README.md" ] && continue

  dest="$TARGET/$name"
  if [ -L "$dest" ]; then
    echo "Already linked: $name"
  elif [ -e "$dest" ]; then
    echo "Skipped (file exists): $name"
  else
    ln -s "$file" "$dest"
    echo "Linked: $name → $file"
  fi
done
