#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

[[ $("$repo_dir/scripts/release-version.sh" v1.7.8-2) == 1.7.8-2 ]]

for invalid in 1.7.8-2 v1.7.8 v1.7.8-1 v01.7.8-2 v1.7.8-2-extra ''; do
  if "$repo_dir/scripts/release-version.sh" "$invalid" >/dev/null 2>&1; then
    echo "Unexpectedly accepted release tag: $invalid" >&2
    exit 1
  fi
done
