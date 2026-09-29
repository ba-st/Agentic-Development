# Contributing

There are several ways to contribute to the project: reporting bugs, sending
feedback, proposing ideas for new features, fixing or adding documentation,
promoting the project, or even contributing code.

This repository provides the development environment, a devcontainer with a
Pharo image and Claude Code, used to work on the
[Buenos Aires Smalltalk](https://github.com/ba-st) projects. It holds no
Smalltalk code of its own: contributions are to the container definition, its
scripts, the agent configuration and the documentation. Changes to a ba-st
project belong in that project's repository and follow its own contribution
guidelines. [Develop in the Pharo image](docs/how-to/develop-in-the-pharo-image.md)
explains how to work on one from inside the devcontainer.

## Reporting issues

You can
[open an issue in the tracker](https://github.com/ba-st/Agentic-Development/issues/new)

When the problem is with the environment itself, say what you ran, what you
expected and what happened instead, and include the host operating system and
display server if it involves the Pharo IDE.

## Contributing Code

- This project is MIT licensed, so any code contribution MUST be under the
  same license.
- Feel free to send pull requests or fork the project.
- Every change must keep the devcontainer building from scratch. If a change
  touches `.devcontainer/`, rebuild the container without cache before sending
  the pull request, and check that `postCreateCommand` completes.

1. Open the repository in the devcontainer
2. Create a new branch to host your code changes, following the
   [naming rules](#feature-branch-naming)
3. Do the changes
4. Run the [linters](#linting) over the files you changed
5. Commit and push your changes to the branch. You may need to add your fork if
   lacking the required permissions to push to the main repo.
6. Create a Pull Request against the `release-candidate` branch

## Branching and Releases

The `release-candidate` branch is the production branch, and should always be in
a usable state: anyone opening the devcontainer from it must get a working
environment. All changes must reach it through a pull request — direct pushes
are not allowed.

### Feature Branch Naming

Branches must follow the pattern `{category}/{issue-id}-{slug}`, where:

- **category** is one of: `feature`, `bugfix`, `docs`, `chore`, `refactor`
- **issue-id** is the GitHub issue number. It is required whenever the work has
  an associated issue, and omitted otherwise, leaving the pattern
  `{category}/{slug}`
- **slug** is a short description in kebab-case

Examples: `feature/12-gemstone-support`, `bugfix/34-x11-socket-permissions`,
`docs/56-pharo-ide-how-to`

Without an issue: `chore/bump-pharo-vm`, `refactor/share-script-helpers`

### Commit Messages

Commit messages must follow the
[Conventional Commits](https://www.conventionalcommits.org/) specification:

```text
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

The **type** maps directly to the branch category:

| Branch category | Commit type |
| --- | --- |
| `feature` | `feat` |
| `bugfix` | `fix` |
| `docs` | `docs` |
| `chore` | `chore` |
| `refactor` | `refactor` |

The **scope** is optional and should name the area of the repository affected:

| Scope | Area |
| --- | --- |
| `devcontainer` | `.devcontainer/` definition: Dockerfile, compose, features |
| `scripts` | The helper scripts in `.devcontainer/scripts/` |
| `pharo` | The Pharo image and VM the container ships |
| `claude` | Claude Code settings and hooks in `.claude/` |
| `agents` | `AGENTS.md` and other instructions for coding agents |
| `ci` | GitHub Actions workflows |

The **description** is a short, imperative-mood summary written in lowercase.

Examples:

```text
feat(scripts): add a --force option to create-pharo-image.sh
fix(devcontainer): create the repos directory before the container starts
docs(contributing): add commit message conventions
chore(pharo): update the Pharo runtime image to v13.1.3
refactor(claude): move the secret patterns into their own file
```

Breaking changes must be indicated by appending `!` after the type/scope, or by
adding a `BREAKING CHANGE:` footer in the commit body. In this repository a
change is breaking when it forces existing users to act, such as a new required
variable in `.devcontainer/.env` or a working image that has to be recreated:

```text
feat(devcontainer)!: mount the reference projects at /reference/ba-st
```

### Pull Request Requirements

- PRs must be merged using the **squash** strategy to keep the branch history
  clean and linear.
- PR titles must comply with the conventional commits style
- A PR that changes how the environment is set up or used must update the
  documentation and `AGENTS.md` in the same PR.

## Feature Workflow

Every feature is planned before it is built, and built in phases that are each
reviewed on their own.

### The Plan

Work on a feature starts with an implementation plan in `PLAN.md`, at the
repository root. The file is gitignored: it is a working document, and the
feature's GitHub issue is its durable copy.

The plan holds:

- **Scope** — what the feature delivers, and what it deliberately leaves out
- **Phases** — each broken into concrete, executable tasks and ending in the
  checks that prove it done: which linters, which commands, which rebuilds
- **Status** — for each phase, whether it is not started, in progress, in review
  or done, with its branch and pull request
- **Recaps** — one for each finished phase, described below
- **Open questions** — anything undecided, and the phase that has to settle it

Once the plan is approved, a feature issue is opened in GitHub mirroring it.
There is one `PLAN.md` at a time.

### Phases

There is no standard set of phases. A feature's plan proposes them, and
approving the plan approves them. Phases should follow the natural layering of
the work, so each one builds on what the previous one finished, and each ends in
the checks that prove it done.

### One Pull Request per Phase

Each phase gets its own branch and pull request, and is reviewed and merged
before the next phase starts. Branches follow the naming rules above, with the
phase appended to the slug: `feature/12-gemstone-support-image`,
`feature/12-gemstone-support-scripts`, and `docs/12-gemstone-support` for the
documentation phase.

A phase's pull request refers to the feature issue with `Part of #12` rather
than a closing keyword, because the issue stays open until the final review.

### Recaps

Consecutive phases may be carried out in different sessions, so the plan must
hold everything the next one needs. Once a phase is reviewed and merged,
`PLAN.md` gains its recap: what was delivered and in which pull request, where
the work departed from the plan and why, what it left for later, and any change
it forces on the phases still ahead. The feature issue is updated to match.

### Closing a Feature

After the last phase, a final review gathers every pending item, TODO and open
question, from the plan, the recaps, the pull request reviews and the code
itself. Each is resolved, or moved into an issue of its own, before the feature
issue is closed.

### Upstream Issues

Work here regularly turns up problems that belong to someone else: the Pharo VM,
Iceberg, the ba-st runtime images, another ba-st project. They are collected in
`ISSUES.md`, at the repository root and gitignored like `PLAN.md`, as drafts
ready to be filed: the project they belong to, a title, the steps to reproduce,
and the workaround used here if any. A maintainer reviews and files them; once
filed, the draft is replaced by a link to the issue, and any workaround in this
repository gets a comment pointing at it.

## Documentation

The project documentation is maintained in this repository in the `docs` folder
and licensed under CC BY-SA 4.0. To contribute some documentation or improve the
existing, feel free to create a branch or fork this repository, make your
changes and send a pull request.

The folder is organized by content type:

| Folder | Purpose |
| --- | --- |
| `docs/tutorial/` | Learning-oriented walkthroughs for newcomers |
| `docs/how-to/` | Goal-oriented recipes for a reader who knows the goal |
| `docs/reference/` | Reference material: scripts, variables, mounts |
| `docs/explanations/` | Clarifications and discussion of concepts |

following the [Diátaxis](https://diataxis.fr/) documentation guidelines.

### Choosing a Folder

Diátaxis sorts documentation by the reader's situation rather than by subject.
Two questions place almost any page:

- Is the reader **studying**, building understanding, or **working**, getting
  something done?
- Is the content **practical**, steps to follow, or **theoretical**, information
  to absorb?

| | Practical | Theoretical |
| --- | --- | --- |
| **Studying** | `docs/tutorial/` | `docs/explanations/` |
| **Working** | `docs/how-to/` | `docs/reference/` |

Tutorials and how-to guides are the pair most often confused:

- A **tutorial** walks a newcomer along a route *we* chose and guarantees a
  successful result. It offers no alternatives and does not digress to explain.
- A **how-to guide** serves a reader who already knows the goal and has the
  background to reach it. It may skip steps that are obvious to a practitioner.

Keep the four modes separate. A tutorial that keeps stopping to explain, or a
how-to that swells into reference, serves neither reader well.

## Style

### Comments

The files in this repository are read far more often than they are changed, by
people and by agents trying to work out why the environment behaves as it does.
Comments explain the reason behind a line, not what it does: why a package is
installed, why a variable has no default, which failure a setting prevents and
what its error message looks like. A change that removes the reason for a
comment removes the comment too.

### Shell Scripts

- Start with `#!/usr/bin/env bash`, a header comment saying what the script is
  for, and `set -euo pipefail`
- Put the logic in a `main` function called as `main "$@"`
- Declare constants with `readonly` and variables inside functions with `local`
- Use `[[ ]]` for tests and `printf` rather than `echo` for output, sending
  errors and warnings to standard error
- Prefer the long form of command options (`--parents`, `--force`) so the
  script reads without a manual page
- Scripts that take arguments answer `--help` with their usage

### Dockerfile

- Use the long form of command options, as in shell scripts
- Keep package lists one per line and sorted, each package accounted for in the
  comment above the `RUN` that installs it
- Pin versions of tools and base images, so a rebuild gives the same environment
- Clean up package manager caches in the same `RUN` that fills them

### YAML

YAML files start with the `---` document marker, except GitHub Actions
workflows, which follow their own conventions (see `.yamllint`).

## Linting

Every file type has a linter, and the devcontainer ships all of them. Run the
ones matching the files you changed before sending a pull request:

| Files | Command |
| --- | --- |
| Markdown | `markdownlint '**/*.md' --ignore pharo --ignore repos` |
| Shell scripts | `shellcheck .devcontainer/scripts/* .claude/hooks/*.sh` |
| YAML | `yamllint .` |

Markdown files must be linted using `markdownlint`, shell scripts using
`shellcheck`, and YAML files using `yamllint`, each with the configuration
checked in at the repository root.
