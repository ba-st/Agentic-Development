# AGENTS.md

Instructions for coding agents working in this repository, or on a Buenos Aires
Smalltalk project from inside the devcontainer it defines. Human contributors
should read [CONTRIBUTING.md](CONTRIBUTING.md); everything there applies to
agents too, and this file only adds what an agent needs on top of it.

## What This Repository Is

A devcontainer for agentic development on the
[ba-st](https://github.com/ba-st) Smalltalk projects: a Debian container with a
Pharo VM and image, Claude Code, the GitHub CLI and the linters the ba-st
projects use. It holds no Smalltalk code. The projects being worked on are
cloned into `repos/`, the directory Iceberg shares between every image (see
[Working on a ba-st Project](#working-on-a-ba-st-project)).

There are two kinds of work, and they follow different rules:

- **Changing the environment** — the container, its scripts, the agent
  configuration, the docs. Follow this repository's
  [CONTRIBUTING.md](CONTRIBUTING.md).
- **Working on a ba-st project** — changing Smalltalk code in one of the cloned
  repositories. Follow that project's own `CONTRIBUTING.md` and `AGENTS.md`
  first; where they disagree with this file, they win.

## Layout

| Path | What it is |
| --- | --- |
| `.devcontainer/` | Container definition: `Dockerfile`, `docker-compose.yml`, `devcontainer.json` |
| `.devcontainer/scripts/` | Helper scripts, installed into `/usr/local/bin` at build time |
| `.devcontainer/.env` | Per-user settings and secrets. Never read it; see [Secrets](#secrets) |
| `.claude/` | Shared Claude Code permissions and hooks |
| `pharo/` | The working Pharo image. Gitignored, disposable |
| `repos/` | Iceberg's shared clones, one per `<org>/<project>`, mounted at `/home/node/iceberg`. Gitignored |
| `/reference` | Other projects on the host, mounted read-only for reference |
| `/opt/pharo/pristine/` | The pristine image the working one is copied from |

Changes to `.devcontainer/scripts/` only reach `/usr/local/bin` when the
container is rebuilt. To try a script before that, run it from
`.devcontainer/scripts/` directly.

`pharo/` and `repos/` are gitignored but not disposable in the same way: the
image can be recreated, but `repos/` holds the clones being worked on, with
their unpushed branches. Never run `git clean -x` (or `-X`) in this repository.

[Develop in the Pharo image](docs/how-to/develop-in-the-pharo-image.md) is the
full guide to the Pharo side; what follows is what an agent must not miss.

## The Pharo Image

| Command | What it does |
| --- | --- |
| `pharo eval "<expression>"` | Evaluates an expression headless and prints the result |
| `pharo test <package pattern> ...` | Runs the tests in the matching packages |
| `pharo metacello install <url> <baseline> --groups=<groups>` | Loads a project |
| `pharo st <file>.st` | Loads and runs a Smalltalk script file |
| `pharo-ui` | Opens the image in the Pharo IDE, for the human, on their X server |
| `create-pharo-image.sh [--force]` | Creates the working image; `--force` replaces it |

Every argument after `pharo` goes to the Pharo command line, so
`pharo --list` shows the available handlers and `pharo <handler> --help` their
options.

Things that are easy to get wrong:

- **Test patterns are regular expressions.** `pharo test "Buoy-.*"` runs every
  Buoy package; `pharo test "Buoy-*"` runs none and still exits successfully.
  Check the count in `Running tests in N Packages` before reporting a pass.
- **Leftovers.** A failing test writes a `.fuel` file with its stack, and an
  error writes `PharoDebug.log`, into the current directory. They are
  gitignored at the repository root, but delete them once read, and do not run
  Pharo from inside a project clone, where they are not ignored.
- **Saving.** `eval` and `test` leave the image unsaved unless given `--save`,
  but `metacello install` saves by default; pass `--no-save` to try a load
  without keeping it. Save the image only when the task calls for it.
- **The image is disposable.** Nothing in it is the source of truth: the Tonel
  files in the project's git clone are. If the image gets into a bad state,
  `create-pharo-image.sh --force` gives a fresh one, and the project is loaded
  again. Say so before doing it, since whatever was only in the image is lost.
- **One image at a time.** Two `pharo` processes on the same image race to save
  it. Run Pharo commands one after another, never in parallel.
- **`pharo-ui` is for humans.** It needs a `DISPLAY` and opens a window an agent
  cannot see. Use the headless `pharo` for everything an agent runs.
- **Failing loads.** If Metacello fails with
  `PrimitiveFailed: primitive #createDirectory: in UnixStore failed`, Iceberg
  cannot write to `/home/node/iceberg`. Run `check-repositories.sh` and report
  its output; do not try to fix the ownership from inside the container.

## Working on a ba-st Project

Iceberg keeps its clones in `/home/node/iceberg`, which is `repos/` in this
repository, one directory per organization and project: Buoy is
`repos/ba-st/Buoy`, and `/home/node/iceberg/ba-st/Buoy` inside the container is
the same directory. A project being worked on is cloned there too, so the clone
being edited is also the one every image resolves the project to.

1. Clone the project into `repos/<org>/<project>`, with an SSH remote like
   Iceberg's own:

    ```bash
    git clone git@github.com:ba-st/Buoy.git repos/ba-st/Buoy
    ```

   If the directory already exists, Iceberg cloned it as a dependency and it may
   be on any version. Do not clone again: check its state with `git status` and
   switch it to the branch to work from.
2. Read the project's `CONTRIBUTING.md`, `AGENTS.md` if there is one, and
   `docs/`. All git work — branch, commit, push — happens in the clone,
   following that project's rules, never in this repository.
3. Make the change in the Tonel files under `source/`, then load the working
   tree into the image. Use the `/home/node/iceberg` path, the one Iceberg knows
   the clone by:

    ```bash
    pharo metacello install tonel:///home/node/iceberg/ba-st/Buoy/source \
      BaselineOfBuoy --groups=Development
    ```

4. Run the project's tests with `pharo test --fail-on-failure "Buoy-.*"`,
   using a pattern that matches the packages in its baseline.
5. Before calling the work done, reproduce what CI sees: commit, then load with
   `gitlocal://` instead of `tonel://` into a fresh image and run the tests
   again. `gitlocal://` reads the commit, so an uncommitted edit is quietly left
   out. To leave the working image alone, make the fresh one elsewhere with
   `PHARO_IMAGE_DIR` and point `PHARO_IMAGE` at it.
6. Lint what changed, as the project's CI does: usually `markdownlint` for
   docs and `shellcheck` for scripts.

**Dependents move shared clones.** Loading a project with `github://` checks out
the version its baseline asks for in every dependency's clone. Loading
Hyperspace, which wants `github://ba-st/Buoy:v8`, switches `repos/ba-st/Buoy`
from whatever branch it was on to `v8`, silently. To test a dependent against a
change in progress, load the changed project from `tonel://` first, `lock` it,
and load the dependent with `onLock: [ :ex :loaded :incoming | ex honor ]`, as
the [how-to](docs/how-to/develop-in-the-pharo-image.md#load-projects-that-depend-on-it)
shows. Locking before loading does not work: the clone stays put, but the
dependent loads without it. Whatever was loaded, confirm the clone is still on
its branch with `git status` before committing.

The [ba-st coding standards](https://github.com/ba-st/Community/blob/main/docs/CodingStandards.md)
apply to every project. The parts that matter most when writing code:

- Source code is in [Tonel](https://github.com/pharo-vcs/tonel) format in the
  `source/` folder.
- Test packages are named after the package under test with a `-Tests` suffix.
  Code without tests is unlikely to be merged.
- Baselines define the `Deployment`, `Tests`, `Tools`,
  `Dependent-SUnit-Extensions`, `CI` and `Development` groups. A new package
  goes into the right ones.
- Projects follow [Semantic Versioning](https://semver.org/). Flag any change
  that breaks backwards compatibility instead of making it quietly.

Most projects run on both Pharo and GemStone/S 64. This container only has
Pharo, so do not assume code is portable just because the tests pass here.

## Checks Before Calling Work Done

- The linters for every file type touched pass, with the configuration at the
  repository root:
  - `markdownlint '**/*.md' --ignore pharo --ignore repos`
  - `shellcheck .devcontainer/scripts/* .claude/hooks/*.sh`
  - `yamllint .`
- For a Smalltalk change, the project's tests pass in a fresh image loaded from
  the commit with `gitlocal://`, and the run reports a non-zero package count.
- If the change affects how the environment is built, set up or used, the docs
  and this file say so.

Report what was run and what it printed. If a check could not be run, such as a
container rebuild from inside the container, say so instead of assuming it
passes.

## Git and GitHub

- Branch names, commit messages and pull request titles follow
  [CONTRIBUTING.md](CONTRIBUTING.md#branching-and-releases): `{category}/{issue-id}-{slug}`
  branches and Conventional Commits.
- Never commit to or push `release-candidate`. All changes reach it through a
  pull request.
- Commit, push, open pull requests or file issues only when asked.
- `gh` is authenticated through `GH_TOKEN` when the user has set it. If a `gh`
  command fails with an authentication error, report it; do not ask for the
  token.
- `PLAN.md` and `ISSUES.md` are gitignored working documents (see
  [the feature workflow](CONTRIBUTING.md#feature-workflow)). Keep them up to
  date as work proceeds, and never commit them. Problems found in someone else's
  project, such as Pharo, Iceberg or another ba-st repository, are drafted in
  `ISSUES.md` rather than filed directly.

## Secrets

The container holds secrets: `GH_TOKEN`, and whatever the user adds to
`.devcontainer/.env`. Anything a command prints ends up in the conversation
transcript, so:

- Never read, print, copy or edit a `.env` file. To see which variables one
  defines, list the names only:
  `cut --delimiter== --fields=1 .devcontainer/.env`
- Never print the environment (`env`, `printenv`, `export -p`, `set`,
  `/proc/*/environ`), or expand a variable whose name suggests a secret
  (`$GH_TOKEN`, `$*_API_KEY`, `$*_PASSWORD`).
- Never read the environment from Pharo (`OSEnvironment`).
- Tools that need a secret already find it: `gh` reads `GH_TOKEN` by itself.

The deny rules in `.claude/settings.json` and the
`.claude/hooks/block-secret-output.sh` hook enforce these rules for Claude Code.
They are a safety net, not the rule itself: a command they do not catch is not
thereby allowed. If a task seems to need a secret's value, stop and ask.
