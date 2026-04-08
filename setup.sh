#!/bin/bash

SKILLS_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$HOME/.claude/commands"

if [ -L "$TARGET" ]; then
  echo "Symlink already exists: $TARGET → $(readlink "$TARGET")"
  exit 0
fi

if [ -d "$TARGET" ]; then
  echo "Warning: $TARGET already exists as a directory."
  echo "Back it up or remove it, then re-run this script."
  exit 1
fi

mkdir -p "$HOME/.claude"
ln -s "$SKILLS_DIR" "$TARGET"
echo "Linked $TARGET → $SKILLS_DIR"
