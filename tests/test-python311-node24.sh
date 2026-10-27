#!/bin/bash
set -euo pipefail

TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../src/python311-node24" && pwd)"
TEST_DIR="$(mktemp -d)"
TEST_NAME="$(basename "$TEST_DIR" | tr '[:upper:]' '[:lower:]')"

cleanup() {
  local status=$?
  local container_id
  local container_info
  local container_name
  local container_image
  local container_repository
  local container_workspace
  local image_ref
  local image_repository
  local image_info
  local image_id
  local image_tags

  trap - EXIT
  while IFS= read -r container_id; do
    [ -n "$container_id" ] || continue
    if ! container_info="$(docker inspect --format '{{.Name}}|{{.Config.Image}}|{{index .Config.Labels "devcontainer.local_folder"}}' "$container_id" 2>/dev/null)"; then
      status=1
      continue
    fi
    IFS='|' read -r container_name container_image container_workspace <<< "$container_info"
    container_name="${container_name#/}"
    if [[ "$container_workspace" != "$TEST_DIR" || ! "$container_name" =~ ^[[:alnum:]][[:alnum:]_.-]*$ ]]; then
      status=1
      continue
    fi
    container_repository="${container_image%:*}"
    if [[ "$container_repository" == "vsc-${TEST_NAME}-"*-features || "$container_repository" == "vsc-${TEST_NAME}-"*-features-uid ]]; then
      if docker stop "$container_id" >/dev/null; then
        docker rm "$container_id" >/dev/null || status=$?
      else
        status=$?
      fi
    else
      status=1
    fi
  done < <(docker ps -aq --filter "label=devcontainer.local_folder=$TEST_DIR" 2>/dev/null || true)

  while IFS= read -r image_ref; do
    [ -n "$image_ref" ] || continue
    if ! image_info="$(docker image inspect --format '{{.Id}}|{{range .RepoTags}}{{.}} {{end}}' "$image_ref" 2>/dev/null)"; then
      status=1
      continue
    fi
    image_id="${image_info%%|*}"
    image_tags="${image_info#*|}"
    if [[ ! "$image_id" =~ ^sha256:[[:xdigit:]]{64}$ || " $image_tags " != *" $image_ref "* ]]; then
      status=1
      continue
    fi
    docker image rm "$image_ref" >/dev/null || status=$?
  done < <(
    docker image ls --format '{{.Repository}}:{{.Tag}}' 2>/dev/null |
      while IFS= read -r image_ref; do
        image_repository="${image_ref%:*}"
        if [[ "$image_repository" == "vsc-${TEST_NAME}-"*-features || "$image_repository" == "vsc-${TEST_NAME}-"*-features-uid ]]; then
          printf '%s\n' "$image_ref"
        fi
      done
  )

  rm -rf "$TEST_DIR" || status=$?
  exit "$status"
}
trap cleanup EXIT

cp -R "$TEMPLATE_DIR/." "$TEST_DIR/"
mkdir -p "$TEST_DIR/.devcontainer/.claude"
printf '{}\n' > "$TEST_DIR/.devcontainer/.claude/.claude.json"
devcontainer read-configuration --workspace-folder "$TEST_DIR" >/dev/null
devcontainer build --workspace-folder "$TEST_DIR"
devcontainer up --workspace-folder "$TEST_DIR"

EXPECTED_TZ="$(sed -n 's/^TZ=//p' "$TEST_DIR/.devcontainer/.env")"
test -n "$EXPECTED_TZ"
assert_runtime() {
  devcontainer exec --workspace-folder "$TEST_DIR" env "EXPECTED_TZ=$EXPECTED_TZ" bash -c '
set -euo pipefail

test "$(id -un)" = vscode
python -c "import sys; assert sys.version_info[:2] == (3, 11)"
node -e "if (Number(process.versions.node.split(\".\")[0]) !== 24) process.exit(1)"
[[ "$(pdm --version)" == *2.29.3* ]]
command -v claude >/dev/null
claude --version
command -v codex >/dev/null
codex --version
[[ "$TZ" == "$EXPECTED_TZ" ]]

workspace_root="$(cd "$CODEX_HOME/../.." && pwd)"
test -L /home/vscode/.local/share/muse/sessions
[[ "$(readlink -f /home/vscode/.local/share/muse/sessions)" == "$workspace_root/.devcontainer/.muse-data/sessions" ]]
test -L /home/vscode/.claude.json
[[ "$(readlink -f /home/vscode/.claude.json)" == "$workspace_root/.devcontainer/.claude/.claude.json" ]]
cmp -s "$workspace_root/.devcontainer/claude/settings.json" "$CLAUDE_CONFIG_DIR/settings.json"
sed "s|__WORKSPACE_ROOT__|$workspace_root|g" "$workspace_root/.devcontainer/codex/config.toml" | cmp -s - "$CODEX_HOME/config.toml"
cmp -s "$workspace_root/.devcontainer/codex/rules/confirm-rm.rules" "$CODEX_HOME/rules/confirm-rm.rules"
cmp -s "$workspace_root/.devcontainer/muse/settings.json" /home/vscode/.config/muse/settings.json
'
}

assert_runtime
CONTAINER_ID="$(docker ps -q --filter "label=devcontainer.local_folder=$TEST_DIR")"
test -n "$CONTAINER_ID"
test "$(printf '%s\n' "$CONTAINER_ID" | wc -l)" -eq 1
CONTAINER_INFO="$(docker inspect --format '{{.Name}}|{{.Config.Image}}|{{index .Config.Labels "devcontainer.local_folder"}}' "$CONTAINER_ID")"
IFS='|' read -r CONTAINER_NAME CONTAINER_IMAGE CONTAINER_WORKSPACE <<< "$CONTAINER_INFO"
CONTAINER_NAME="${CONTAINER_NAME#/}"
CONTAINER_REPOSITORY="${CONTAINER_IMAGE%:*}"
[[ "$CONTAINER_WORKSPACE" == "$TEST_DIR" ]]
[[ "$CONTAINER_NAME" =~ ^[[:alnum:]][[:alnum:]_.-]*$ ]]
[[ "$CONTAINER_REPOSITORY" == "vsc-${TEST_NAME}-"*-features || "$CONTAINER_REPOSITORY" == "vsc-${TEST_NAME}-"*-features-uid ]]
docker stop "$CONTAINER_ID" >/dev/null
devcontainer up --workspace-folder "$TEST_DIR"
devcontainer run-user-commands --workspace-folder "$TEST_DIR"
assert_runtime
