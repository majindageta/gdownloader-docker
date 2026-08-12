#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=../versions.env
source "$repo_dir/versions.env"

tag=${1:-}
expected="v${GDOWNLOADER_VERSION}-${CONTAINER_REVISION}"

if [[ "$tag" != "$expected" ]]; then
  echo "Release tag '$tag' does not match '$expected' from versions.env" >&2
  exit 1
fi

printf '%s-%s\n' "$GDOWNLOADER_VERSION" "$CONTAINER_REVISION"
