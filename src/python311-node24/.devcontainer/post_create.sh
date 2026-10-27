#!/bin/bash
set -euo pipefail

python --version
printf 'NodeJS %s\n' "$(node --version)"

# Use PDM's Python installer to avoid the standalone binary's glibc requirement.
# https://pdm-project.org/latest/#install-via-python-script
curl -fsSL https://pdm-project.org/install-pdm.py | python - -v 2.29.3 >/dev/null
hash -r
pdm --version

npm install -g npm@latest >/dev/null
printf 'NPM %s\n' "$(npm --version)"
npm install -g @openai/codex >/dev/null

MUSE_INSTALLER="$(mktemp)"
curl -fsSL https://dev.meta.ai/install.sh -o "$MUSE_INSTALLER"
MUSE_NO_MODIFY_PATH=1 bash "$MUSE_INSTALLER"
rm -f "$MUSE_INSTALLER"
hash -r
muse --version

MUSE_ALIAS="alias muse='muse --disable-sandbox'"
if ! grep -qF "$MUSE_ALIAS" /home/vscode/.bashrc 2>/dev/null; then
  printf '\n%s\n' "$MUSE_ALIAS" >> /home/vscode/.bashrc
fi

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ".devcontainer time zone: $TZ"

if [ ! -f "$CONFIG_DIR/.claude/keybindings.json" ]; then
  cp "$CONFIG_DIR/claude/keybindings.json" "$CONFIG_DIR/.claude/keybindings.json"
fi
if [ ! -f "$CONFIG_DIR/.codex/config.toml" ]; then
  sed "s|__WORKSPACE_ROOT__|$(cd "$CONFIG_DIR/.." && pwd)|g" "$CONFIG_DIR/codex/config.toml" > "$CONFIG_DIR/.codex/config.toml"
fi
if [ ! -f "$CONFIG_DIR/.codex/rules/confirm-rm.rules" ]; then
  mkdir -p "$CONFIG_DIR/.codex/rules"
  cp "$CONFIG_DIR/codex/rules/confirm-rm.rules" "$CONFIG_DIR/.codex/rules/confirm-rm.rules"
fi
if [ ! -f "$CONFIG_DIR/.claude/settings.json" ]; then
  cp "$CONFIG_DIR/claude/settings.json" "$CONFIG_DIR/.claude/settings.json"
fi
mkdir -p /home/vscode/.config/muse
if [ ! -f /home/vscode/.config/muse/settings.json ]; then
  cp "$CONFIG_DIR/muse/settings.json" /home/vscode/.config/muse/settings.json
fi

bash "$CONFIG_DIR/restore_links.sh"
