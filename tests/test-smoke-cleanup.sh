#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo_dir/versions.env"

image="gdownloader-docker:${GDOWNLOADER_VERSION}-${CONTAINER_REVISION}"
fixture=$(mktemp -d)

cleanup_fixture() {
  docker run --rm --entrypoint /bin/sh \
    -v "$fixture:/fixture" \
    "$image" -c 'chmod -R a+rwX /fixture' >/dev/null 2>&1 || true
  rm -rf "$fixture" >/dev/null 2>&1 || true
}
trap cleanup_fixture EXIT

docker run --rm --entrypoint /bin/sh \
  -v "$fixture:/fixture" \
  "$image" -c 'mkdir -p /fixture/nested && touch /fixture/nested/file && chmod 000 /fixture/nested'

bash "$repo_dir/tests/lib/cleanup-bind-mount.sh" "$image" "$fixture"

[[ ! -e "$fixture" ]]
