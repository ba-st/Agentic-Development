# Agentic Development

A development environment for working on the
[Buenos Aires Smalltalk](https://github.com/ba-st) projects alongside a coding
agent.

[![Pharo 13](https://img.shields.io/badge/Pharo-13-informational)](https://pharo.org)

Quick links

- [Develop in the Pharo image](docs/how-to/develop-in-the-pharo-image.md)
- [Contributing](CONTRIBUTING.md)
- [Instructions for agents](AGENTS.md)
- [Report a defect](https://github.com/ba-st/Agentic-Development/issues/new)

## What You Get

A devcontainer with everything needed to work on a ba-st project from the
terminal, the Pharo IDE, or a coding agent:

- A Pharo 13 image, taken from the same runtime image ba-st's CI uses, and a
  VM that runs it both headless and with the IDE
- Iceberg clones shared between every image, so a project and its dependencies
  are cloned once, into a directory you can browse from the host
- [Claude Code](https://claude.com/claude-code), set up with permissions and
  hooks that keep secrets out of the conversation
- The GitHub CLI, and the linters the ba-st projects run in CI: `markdownlint`,
  `shellcheck` and `yamllint`

## Requirements

- Docker
- An editor that supports devcontainers, such as VS Code with the Dev
  Containers extension
- An SSH agent holding a key GitHub accepts, which the editor forwards into the
  container: Iceberg's clones use SSH remotes
- To open the Pharo IDE, an X server on the host, reachable through
  `/tmp/.X11-unix`. Everything else works headless without one

## Getting Started

1. Clone this repository and create your settings file from the example:

    ```bash
    git clone git@github.com:ba-st/Agentic-Development.git
    cd Agentic-Development
    cp .devcontainer/.env.example .devcontainer/.env
    ```

2. Edit `.devcontainer/.env`. Every setting is optional, and the example
   explains each one: the folder of other projects to mount read-only at
   `/reference`, the timezone, the X display for the IDE, and a GitHub token for
   `gh`.
3. Open the folder in your editor and reopen it in the container. The first
   build creates the working Pharo image in `pharo/`.
4. Run `claude` in the container's terminal and log in. The login is kept in a
   Docker volume, so it survives rebuilds.

Then clone the project to work on into `repos/`, where Iceberg keeps its
clones, and load it into the image:

```bash
git clone git@github.com:ba-st/Buoy.git repos/ba-st/Buoy
pharo metacello install tonel:///home/node/iceberg/ba-st/Buoy/source \
  BaselineOfBuoy --groups=Development
pharo test "Buoy-.*"
```

[Develop in the Pharo image](docs/how-to/develop-in-the-pharo-image.md) covers
the rest: opening the IDE, loading what CI loads, testing projects that depend
on the one you are changing, and starting over with a fresh image.

## Layout

| Path | What it is |
| --- | --- |
| `.devcontainer/` | The container definition and its helper scripts |
| `.claude/` | Claude Code permissions and hooks, shared by everyone |
| `docs/` | Documentation |
| `pharo/` | The working Pharo image. Gitignored, and safe to recreate |
| `repos/` | The projects you work on and their dependencies, one clone per `<org>/<project>`. Gitignored, but holds your work |

## Contributing

Check the [Contribution Guidelines](CONTRIBUTING.md). Changes to a ba-st
project itself go to that project's repository.

## License

- The code is licensed under [MIT](LICENSE).
- The documentation is licensed under
  [CC BY-SA 4.0](http://creativecommons.org/licenses/by-sa/4.0/).
