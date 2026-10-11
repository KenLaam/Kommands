#!/bin/bash
# Install togif: link the command into ~/.local/bin and copy the Finder Quick Action.

set -u

PROG=$(basename "$0")
SRC_DIR=$(cd "$(dirname "$0")" && pwd -P) || exit 1
readonly PROG SRC_DIR
readonly SCRIPT="$SRC_DIR/togif.zsh"
readonly WORKFLOW_NAME="Convert to GIF.workflow"
readonly WORKFLOW_SRC="$SRC_DIR/$WORKFLOW_NAME"
readonly BIN_DIR="$HOME/.local/bin"
readonly LINK="$BIN_DIR/togif"
readonly SERVICES_DIR="$HOME/Library/Services"
readonly WORKFLOW_DST="$SERVICES_DIR/$WORKFLOW_NAME"
readonly PBS=/System/Library/CoreServices/pbs

usage() {
  cat <<EOF
Usage: $PROG [options]

Links togif into ~/.local/bin and copies the "Convert to GIF" Quick Action
into ~/Library/Services. Running it again is safe.

  --no-quick-action  link the command only
  --force            replace a ~/.local/bin/togif this installer did not create
                     (the old one is kept as togif.backup-<timestamp>)
  --uninstall        remove the command link and the Quick Action
  -h, --help         show this help
EOF
}

say() {
  printf '%s\n' "$*"
}

warn() {
  printf '%s: %s\n' "$PROG" "$*" >&2
}

owns_link() {
  [ -L "$LINK" ] && [ "$(readlink "$LINK")" = "$SCRIPT" ]
}

describe_link_target() {
  if [ -L "$LINK" ]; then
    printf 'a symlink to %s' "$(readlink "$LINK")"
  elif [ -d "$LINK" ]; then
    printf 'a directory'
  else
    printf 'a regular file'
  fi
}

refresh_services() {
  [ -x "$PBS" ] && "$PBS" -update
  return 0
}

install_command() {
  if owns_link; then
    say "togif: already installed at $LINK"
    return 0
  fi

  mkdir -p "$BIN_DIR" || return 1

  if [ -e "$LINK" ] || [ -L "$LINK" ]; then
    if [ "$force" -eq 0 ]; then
      warn "$LINK exists and is $(describe_link_target), not a link created by this installer."
      warn "Re-run with --force to back it up and replace it."
      return 1
    fi
    backup="$LINK.backup-$(date +%Y%m%d-%H%M%S)"
    while [ -e "$backup" ] || [ -L "$backup" ]; do
      backup="$backup-$$"
    done
    mv "$LINK" "$backup" || return 1
    say "togif: moved the existing $LINK to $backup"
  fi

  ln -s "$SCRIPT" "$LINK" || return 1
  say "togif: linked $LINK -> $SCRIPT"
}

install_quick_action() {
  if [ -d "$WORKFLOW_DST" ] && diff -rq "$WORKFLOW_SRC" "$WORKFLOW_DST" >/dev/null 2>&1; then
    say "Quick Action: already installed at $WORKFLOW_DST"
    return 0
  fi

  mkdir -p "$SERVICES_DIR" || return 1
  rm -rf "$WORKFLOW_DST" || return 1
  cp -R "$WORKFLOW_SRC" "$WORKFLOW_DST" || return 1
  refresh_services
  say "Quick Action: installed at $WORKFLOW_DST"
  say "  In Finder: right-click a video > Quick Actions > Convert to GIF."
  say "  If it is missing, enable it under Quick Actions > Customize…"
}

check_dependencies() {
  missing=""
  for tool in ffmpeg ffprobe; do
    if ! command -v "$tool" >/dev/null 2>&1 &&
       [ ! -x "/opt/homebrew/bin/$tool" ] && [ ! -x "/usr/local/bin/$tool" ]; then
      missing="$missing $tool"
    fi
  done
  if [ -n "$missing" ]; then
    warn "warning:$missing not found. Install with: brew install ffmpeg"
  fi

  case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
      warn "warning: $BIN_DIR is not on your PATH. Add this line to ~/.zshrc:"
      warn '  export PATH="$HOME/.local/bin:$PATH"'
      ;;
  esac
}

uninstall() {
  if owns_link; then
    rm "$LINK" || return 1
    say "togif: removed $LINK"
  elif [ -e "$LINK" ] || [ -L "$LINK" ]; then
    warn "$LINK is $(describe_link_target), not a link created by this installer. Left alone."
  else
    say "togif: not installed"
  fi

  if [ "$quick_action" -eq 0 ]; then
    return 0
  fi
  if [ -e "$WORKFLOW_DST" ]; then
    rm -rf "$WORKFLOW_DST" || return 1
    refresh_services
    say "Quick Action: removed $WORKFLOW_DST"
  else
    say "Quick Action: not installed"
  fi
}

force=0
quick_action=1
action=install

while [ $# -gt 0 ]; do
  case "$1" in
    --no-quick-action) quick_action=0 ;;
    --force) force=1 ;;
    --uninstall) action=uninstall ;;
    -h|--help) usage; exit 0 ;;
    *)
      warn "unknown argument: $1"
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if [ "$action" = uninstall ]; then
  uninstall
  exit $?
fi

status=0
install_command || status=1
if [ "$quick_action" -eq 1 ]; then
  install_quick_action || status=1
fi
check_dependencies
exit $status
