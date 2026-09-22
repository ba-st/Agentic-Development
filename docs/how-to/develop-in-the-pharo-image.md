# Develop in the Pharo image

Recipes for the Pharo side of the devcontainer: opening the IDE, running the
image headless, working on a ba-st project, and starting over when an image
gets wedged.

The devcontainer ships the VM and a pristine Pharo image; the image you actually
work in lives in `pharo/`, which is gitignored. It is created for you when the
container is created.

## Open the IDE

Inside the container, that is the whole of it:

```bash
pharo-ui &
```

The IDE opens on your desktop. `pharo-ui` passes everything after it to Pharo,
and reads `PHARO_IMAGE` if you want a different image than the one in
`pharo/`.

It draws on the X server of the machine running Docker, over the socket
bind-mounted at `/tmp/.X11-unix`, and needs `DISPLAY` to name that server.
`DISPLAY` is inherited from the shell that started the devcontainer and is not
defaulted, because guessing is worse than failing: on a Plasma Wayland session
the session's own XWayland server is `:1`, and `:0` belongs to something else
and refuses the connection. Set it in `.devcontainer/.env` if your shell has
none.

No `xhost` call is normally needed — the X server already admits the uid the
container draws as. If it does not, see the last section.

## Run the image headless

Same image, no window:

```bash
pharo eval "3 + 4"
pharo test --junit-xml-output "Buoy-.*"
pharo metacello install github://ba-st/Buoy:release-candidate BaselineOfBuoy
```

`pharo` takes the same arguments as the `pharo` command in ba-st's runtime
image, so anything written for CI runs here unchanged. `eval` and `test` leave
the image unsaved unless given `--save`; `metacello install` saves it unless
given `--no-save`.

The pattern `pharo test` takes is read as a **regular expression** first, and
only as a glob if it does not parse as one. So `Buoy-.*` selects every Buoy
package, while `Buoy-*` is a valid regex that matches none — and a run that
matched nothing prints `0 run, 0 passes` and exits successfully, so it reads as
a pass. Check the package count in `Running tests in N Packages` before
believing a green run.

## Where the clones live

Metacello loads a `github://` project by having Iceberg clone it, and every
dependency in the tree gets a clone of its own. Those clones are shared between
every image in this container, in `/home/node/iceberg`, one directory per
GitHub organization and project: Buoy lands in `/home/node/iceberg/ba-st/Buoy`.
Load a project once and the next image fetches rather than clones.

`/home/node/iceberg` is the repository's `repos/` directory, bind-mounted, so
the same clone is `repos/ba-st/Buoy` from the host and from `/workspace`. That
makes the clones outlive a container rebuild and a fresh working image, and
lets you browse them from the host. It also means they are gitignored files of
this repository: a `git clean -xdf` here deletes every one of them, along with
the working image.

Nothing needs enabling — the pristine image is built with
`IceLibgitRepository shareRepositoriesBetweenImages: true`, and every working
image inherits it. To confirm where a given image is putting them:

```bash
pharo eval "IceLibgitRepository repositoriesLocation fullName"
```

An image that answers a path under `pharo-local/` is not sharing, and will
clone the whole tree for itself.

`repos/` has to exist on the host before the container starts, or Docker
creates it as root and the container, which writes as uid 1000, cannot create
anything in it. The `initializeCommand` in `devcontainer.json` creates it on
the host for you. Iceberg's only complaint about a directory it cannot write to
is `PrimitiveFailed: primitive #createDirectory: in UnixStore failed`, which
names neither the path nor the reason; `check-repositories.sh` runs on
container creation and says it plainly instead. Run it any time to check.

Two things this does not cover. The Monticello package cache stays per-image in
`pharo/pharo-local/package-cache`, which is fine — it is small, and it rides
along on the repository bind mount. And the clones carry **SSH** remotes, so
fetching them depends on VS Code forwarding your SSH agent into the container;
`ssh-add -l` shows whether it did.

## Work on a ba-st project

A project you work on lives in the same place Iceberg would put it, so the
clone you edit and the clone every image resolves the project to are one and the
same. Clone it there with an SSH remote, like Iceberg's own:

```bash
git clone git@github.com:ba-st/Buoy.git repos/ba-st/Buoy
```

If the directory is already there, Iceberg cloned it as a dependency of
something else, and it may be sitting on whatever version that project asked
for. Check it out on the branch you want instead of cloning again:

```bash
git -C repos/ba-st/Buoy switch release-candidate
git -C repos/ba-st/Buoy pull
```

Then work in `repos/ba-st/Buoy`: branch, edit, commit and push there, with the
project's own `CONTRIBUTING.md` as the rules.

### Load the project's code

Which URL you give Metacello decides whether it reads the working tree or the
last commit. Use the `/home/node/iceberg` path, the one Iceberg knows the clone
by, rather than `/workspace/repos`:

```bash
# The working tree, uncommitted edits included.
pharo metacello install tonel:///home/node/iceberg/ba-st/Buoy/source \
  BaselineOfBuoy --groups=Development

# What git has committed on the current branch.
pharo metacello install gitlocal:///home/node/iceberg/ba-st/Buoy/source \
  BaselineOfBuoy --groups=CI
```

`gitlocal://` goes through Iceberg, which reads packages out of the commit: a
package that exists only on disk fails the load with
`KeyNotFound: key 'BaselineOf…' not found`, and an edit you have not committed
is quietly not loaded. Use it to reproduce what CI sees; use `tonel://` while
you are still working.

### Load projects that depend on it

Because clones are shared, a project you are working on is also the clone every
dependent project resolves to. Load one of them with `github://` and Metacello
checks out the version *its* baseline asks for: loading Hyperspace, whose
baseline wants `github://ba-st/Buoy:v8`, moves `repos/ba-st/Buoy` off your
branch and onto `v8`, without a word.

To load a dependent against your working tree instead, load your project first,
lock it, and let the dependent's load honor the lock. `metacello install` has no
option for either, so put it in a script:

```smalltalk
"load-hyperspace-on-local-buoy.st"
Metacello new
  baseline: 'Buoy';
  repository: 'tonel:///home/node/iceberg/ba-st/Buoy/source';
  load: 'Development';
  lock.
Metacello new
  baseline: 'Hyperspace';
  repository: 'github://ba-st/Hyperspace:release-candidate';
  onLock: [ :ex :loaded :incoming | ex honor ];
  load: 'Tests'.
Smalltalk snapshot: true andQuit: true.
```

```bash
pharo st load-hyperspace-on-local-buoy.st
pharo test "Hyperspace-.*"
```

Load the locked project before locking it. A lock on a project that is not
loaded yet keeps its clone where it is, but the dependent then loads without it,
and its tests fail on undeclared classes.

Before committing in a shared clone, `git -C repos/ba-st/Buoy status` confirms
you are still on your branch.

## Start over with a fresh image

Nothing in `pharo/` is tracked, so a wedged image costs nothing to
throw away:

```bash
create-pharo-image.sh --force
```

That deletes `Pharo.image` and `Pharo.changes` and copies the pristine pair back
in. Anything saved in the image and not committed to git goes with them, so
commit first. Without `--force` the script leaves an existing image alone, which
is why it is safe to rerun and why it runs on every rebuild.

To leave the working image where it is and check a load in a clean one, put the
copy somewhere else with `PHARO_IMAGE_DIR` and point `PHARO_IMAGE` at it:

```bash
PHARO_IMAGE_DIR=/tmp/fresh create-pharo-image.sh --force
PHARO_IMAGE=/tmp/fresh/Pharo.image pharo metacello install \
  gitlocal:///home/node/iceberg/ba-st/Buoy/source BaselineOfBuoy --groups=CI
PHARO_IMAGE=/tmp/fresh/Pharo.image pharo test --junit-xml-output "Buoy-.*"
```

## When the window does not appear

- **`pharo-ui: DISPLAY is unset`** — the shell that started the devcontainer had
  no `DISPLAY`. Set it in `.devcontainer/.env` and rebuild.
- **`Authorization required, but no authorization protocol specified`** — the X
  server named by `DISPLAY` will not admit the container. Check you are pointing
  at your own session's server: with several sockets in `/tmp/.X11-unix`, the one
  your session owns is the one owned by your uid. Failing that, run
  `xhost +SI:localuser:$(id -un 1000)` on the host once per login session, which
  admits exactly the uid the container draws as and nothing else. `xhost` is
  `xorg-xhost` on Arch and Manjaro, `x11-xserver-utils` on Debian and Ubuntu.
- **`MESA: error: Failed to query drm device` and no window** — the container has
  no `/dev/dri`, so Mesa cannot make a hardware GL screen. `pharo-ui` already
  sets `LIBGL_ALWAYS_SOFTWARE=1` for this; if you have overridden it, don't.
- **The image runs but never opens a window, printing nothing at all** — that is
  the signature of a headless-only VM, not a display problem. Do not try to
  confirm it with `pharo eval "Smalltalk isHeadless"`: the `pharo` wrapper passes
  `--headless` itself, so the answer is always `true` and says nothing about the
  VM. What to check is which VM you are running. The one this container builds,
  in the `pharo-vm` stage of `.devcontainer/Dockerfile`, comes from the
  `pharo-spur64` build and opens windows; a `pharo-spur64-headless` build, which
  is what ba-st's runtime image ships, writes `--headless` into every image's
  arguments and cannot open one whatever it is asked for. `--interactive` will
  not fix it.
- **Do not debug this by invoking the VM yourself** —
  `/opt/pharo/vm/pharo <image> eval ...`, without `--headless` and without a
  display it can reach, idles forever with no output and no error, and leaves a
  second VM on your working image. `pharo` and `pharo-ui` exist so that neither
  happens.
- **Two IDEs on one image** — nothing prevents it, and two VMs writing one
  `.changes` file corrupts it. `ps -eo args | grep vm/lib/pharo` lists them.
