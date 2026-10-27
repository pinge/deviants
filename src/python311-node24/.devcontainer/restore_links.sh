#!/bin/bash
set -euo pipefail

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$CONFIG_DIR/.." && pwd)"

mkdir -p "$CONFIG_DIR/.claude" "$CONFIG_DIR/.codex" "$CONFIG_DIR/.muse-data/sessions" /home/vscode/.local/share/muse

if [ ! -e /home/vscode/.claude.json ] && [ -f "$CONFIG_DIR/.claude/.claude.json" ]; then
  ln -sfn "$CONFIG_DIR/.claude/.claude.json" /home/vscode/.claude.json
fi
if [ -f /home/vscode/.claude.json ] && [ ! -L /home/vscode/.claude.json ] && [ ! -f "$CONFIG_DIR/.claude/.claude.json" ]; then
  cp /home/vscode/.claude.json "$CONFIG_DIR/.claude/.claude.json"
  ln -sf "$CONFIG_DIR/.claude/.claude.json" /home/vscode/.claude.json
fi

MUSE_LINK="/home/vscode/.local/share/muse/sessions"
if [ ! -e "$MUSE_LINK" ]; then
  ln -sfn "$CONFIG_DIR/.muse-data/sessions" "$MUSE_LINK"
fi
