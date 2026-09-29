#!/usr/bin/env bash
#
# Warn if the shared Iceberg repositories directory cannot be written to.

set -euo pipefail

readonly REPOSITORIES_DIR=/home/node/iceberg

main() {
  if [[ ! -d $REPOSITORIES_DIR ]]; then
    printf 'No %s. docker-compose.yml should be mounting it.\n' \
      "$REPOSITORIES_DIR" >&2
    return 0
  fi

  if [[ -w $REPOSITORIES_DIR ]]; then
    return 0
  fi

  local owner running_as
  owner=$(stat --format '%U:%G' "$REPOSITORIES_DIR")
  running_as="$(id --user --name) ($(id --user))"

  cat >&2 <<WARNING

  WARNING: Iceberg cannot write to its repositories directory, so Metacello
  will fail to load anything, reporting only:

      PrimitiveFailed: primitive #createDirectory: in UnixStore failed

      directory: $REPOSITORIES_DIR
      owned by:  $owner
      we are:    $running_as

WARNING
  return 0
}

main "$@"
