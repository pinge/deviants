# 🚢 devcontainers

Dev Container templates for common development environments.

## Templates

- 🐍 ✳️ [`python311-node24`](src/python311-node24/README.md): Python 3.11, Node.js 24, Claude, Codex, and Muse.
- 🐍 ✳️ [`python313-node24`](src/python313-node24/README.md): Python 3.13, Node.js 24, Claude, Codex, and Muse.

## Features

- 🤖 Claude, Codex, and Muse
- 🔐 Credentials and sessions survive container rebuilds
- 🌍 Container inherits the host time zone
- ⚙️ Sane VS Code defaults

## How can I use the Templates?


### 1. Using [@devcontainers/cli](https://containers.dev/supporting#devcontainer-cli)

```sh
npm install --global @devcontainers/cli

devcontainer templates apply \
  --template-id ghcr.io/pinge/devcontainers/python311-node24:latest \
  --workspace-folder .
```

or

```sh
npx --yes --package @devcontainers/cli devcontainer templates apply \
  --template-id ghcr.io/pinge/devcontainers/python311-node24:latest \
  --workspace-folder .
```

### 2. Using supporting tools

A variety of tools and services [support](https://containers.dev/supporting) the Dev Container Spec and may provide direct integrations with the Templates in this repo. You can also customize your dev container with additional available [Features](https://containers.dev/features).

For more information, see [VS Code](https://code.visualstudio.com/docs/devcontainers/create-dev-container#_automate-dev-container-creation) and [GitHub Codespaces](https://docs.github.com/en/codespaces/setting-up-your-project-for-codespaces/adding-a-dev-container-configuration/introduction-to-dev-containers#using-a-predefined-dev-container-configuration).

## References

- https://github.com/devcontainers/spec/blob/main/docs/specs/devcontainer-templates.md
- https://github.com/devcontainers/spec/blob/main/docs/specs/devcontainer-templates-distribution.md
- https://github.com/devcontainers/template-starter
- https://github.com/devcontainers/action
