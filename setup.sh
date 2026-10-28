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

# Symlink each skill folder (skills/<name>/SKILL.md) into the skills directory
SKILLS_TARGET="$HOME/.claude/skills"
mkdir -p "$SKILLS_TARGET"

for dir in "$SKILLS_DIR"/skills/*/; do
  [ -f "$dir/SKILL.md" ] || continue
  dir="${dir%/}"
  name="$(basename "$dir")"

  dest="$SKILLS_TARGET/$name"
  if [ -L "$dest" ]; then
    echo "Already linked: skills/$name"
  elif [ -e "$dest" ]; then
    echo "Skipped (folder exists): skills/$name"
  else
    ln -s "$dir" "$dest"
    echo "Linked: skills/$name → $dir"
  fi
done

# Import each always-on rule (rules/*.md) from the global CLAUDE.md
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
touch "$CLAUDE_MD"

for file in "$SKILLS_DIR"/rules/*.md; do
  [ -f "$file" ] || continue
  line="@$file"
  if grep -qxF "$line" "$CLAUDE_MD"; then
    echo "Already imported: rules/$(basename "$file")"
  else
    printf '\n%s\n' "$line" >> "$CLAUDE_MD"
    echo "Imported: $line → $CLAUDE_MD"
  fi
done
