#!/bin/bash
# Link the skills and commands in this repo into the Claude config directory.

set -u

PROG=$(basename "$0")
REPO=$(cd "$(dirname "$0")" && pwd -P) || exit 1
readonly PROG REPO
readonly CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
readonly BACKUP_ROOT="$CONFIG_DIR/backups"

usage() {
  cat <<EOF
Usage: $PROG [options] [<name>...]

Links every skill in skills/ and every command in commands/ into the Claude
config directory (\$CLAUDE_CONFIG_DIR, default ~/.claude). Name one or more
items to link only those. Running it again is safe.

  --force       replace a target this installer did not create
                (the old one is moved to <config>/backups/kommands-<timestamp>/)
  --uninstall   remove the links this installer created
  -h, --help    show this help

Available items:
EOF
  list_items | sed 's/^/  /'
}

say() {
  printf '%s\n' "$*"
}

warn() {
  printf '%s: %s\n' "$PROG" "$*" >&2
}

# Print "<name> <kind>" for everything the repo offers.
list_items() {
  for skill_file in "$REPO"/skills/*/SKILL.md; do
    [ -f "$skill_file" ] || continue
    printf '%s skill\n' "$(basename "$(dirname "$skill_file")")"
  done
  for command_file in "$REPO"/commands/*.md; do
    [ -f "$command_file" ] || continue
    printf '%s command\n' "$(basename "$command_file" .md)"
  done
}

item_exists() {
  list_items | grep -q "^$1 "
}

describe() {
  if [ -L "$1" ]; then
    printf 'a symlink to %s' "$(readlink "$1")"
  elif [ -d "$1" ]; then
    printf 'a directory'
  else
    printf 'a regular file'
  fi
}

present() {
  [ -e "$1" ] || [ -L "$1" ]
}

owned() {
  [ -L "$2" ] && [ "$(readlink "$2")" = "$1" ]
}

# Move a target the installer does not own out of the way, keeping its
# skills/ or commands/ parent so two items with one name cannot collide.
back_up() {
  if [ -z "$backup_dir" ]; then
    backup_dir="$BACKUP_ROOT/kommands-$(date +%Y%m%d-%H%M%S)"
    while present "$backup_dir"; do
      backup_dir="$backup_dir-$$"
    done
  fi
  backup_parent="$backup_dir/$(basename "$(dirname "$1")")"
  mkdir -p "$backup_parent" && mv "$1" "$backup_parent/"
}

link_item() {
  label=$1 src=$2 dst=$3

  if owned "$src" "$dst"; then
    say "$label: already linked"
    unchanged=$((unchanged + 1))
    return
  fi

  if present "$dst"; then
    if [ "$force" -eq 0 ]; then
      warn "$label: $dst is $(describe "$dst"), not a link created by this installer. Skipped (use --force to back it up and replace it)."
      skipped=$((skipped + 1))
      return
    fi
    if ! back_up "$dst"; then
      warn "$label: could not back up $dst. Skipped."
      skipped=$((skipped + 1))
      return
    fi
    say "$label: moved the existing $dst to $backup_parent/"
  fi

  if mkdir -p "$(dirname "$dst")" && ln -s "$src" "$dst"; then
    say "$label: linked $dst"
    linked=$((linked + 1))
  else
    warn "$label: could not link $dst"
    skipped=$((skipped + 1))
  fi
}

unlink_item() {
  label=$1 src=$2 dst=$3

  if owned "$src" "$dst"; then
    if rm "$dst"; then
      say "$label: removed $dst"
      removed=$((removed + 1))
    else
      skipped=$((skipped + 1))
    fi
  elif present "$dst"; then
    warn "$label: $dst is $(describe "$dst"), not a link created by this installer. Left alone."
    skipped=$((skipped + 1))
  else
    say "$label: not installed"
  fi
}

force=0
action=link_item
names=""

while [ $# -gt 0 ]; do
  case "$1" in
    --force) force=1 ;;
    --uninstall) action=unlink_item ;;
    -h|--help) usage; exit 0 ;;
    -*)
      warn "unknown option: $1"
      usage >&2
      exit 2
      ;;
    *)
      if ! item_exists "$1"; then
        warn "unknown item: $1"
        usage >&2
        exit 2
      fi
      names="$names $1"
      ;;
  esac
  shift
done

selected() {
  [ -z "$names" ] && return 0
  case " $names " in
    *" $1 "*) return 0 ;;
  esac
  return 1
}

linked=0 unchanged=0 skipped=0 removed=0
backup_dir=""

# Read the item list on fd 3 so the loop body keeps the caller's stdin.
while read -r name kind <&3; do
  selected "$name" || continue
  case "$kind" in
    skill) "$action" "$name (skill)" "$REPO/skills/$name" "$CONFIG_DIR/skills/$name" ;;
    command) "$action" "$name (command)" "$REPO/commands/$name.md" "$CONFIG_DIR/commands/$name.md" ;;
  esac
done 3<<EOF
$(list_items)
EOF

if [ "$action" = unlink_item ]; then
  say "$removed removed, $skipped left alone"
  for old_backup in "$BACKUP_ROOT"/kommands-*; do
    [ -d "$old_backup" ] && say "Backup of earlier files: $old_backup"
  done
else
  say "$linked linked, $unchanged already linked, $skipped skipped"
  say "Start a new Claude Code session to pick up the changes."
fi

[ "$skipped" -eq 0 ]
