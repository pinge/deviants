#!/bin/bash
set -euo pipefail

workspace_folder="$1"

mkdir -p \
  "${workspace_folder}/.devcontainer/.claude" \
  "${workspace_folder}/.devcontainer/.codex" \
  "${workspace_folder}/.devcontainer/.muse-data/sessions"

# Reads the zone name from /etc/localtime on the host,
# with an unparseable time zone falling back to UTC
container_env_file="${workspace_folder}/.devcontainer/.env"
host_tz=""
if link="$(readlink /etc/localtime 2>/dev/null)" && [[ "$link" == *zoneinfo/* ]]; then
  candidate="${link##*zoneinfo/}"
  if [[ "$candidate" =~ ^[A-Za-z0-9_+-]+(/[A-Za-z0-9_+-]+)+$ ]]; then
    host_tz="$candidate"
  fi
fi
printf 'TZ=%s\n' "${host_tz:-UTC}" > "$container_env_file"
