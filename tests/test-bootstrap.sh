#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=../rootfs/usr/local/lib/gdownloader/bootstrap.sh
source "$repo_dir/rootfs/usr/local/lib/gdownloader/bootstrap.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

prepare_state "$tmp_dir/config" "$tmp_dir/output" "$repo_dir/defaults/config.json"
jq -e '.DownloadsPath == "/output" and .AutomaticUpdates == false and .PreferSystemExecutables == true' "$tmp_dir/config/config.json" >/dev/null
jq -e '.GalleryDLSettings.Enabled == false and .SpotDLSettings.Enabled == false' "$tmp_dir/config/config.json" >/dev/null

printf '{"marker":"keep"}\n' > "$tmp_dir/config/config.json"
before=$(cksum "$tmp_dir/config/config.json")
prepare_state "$tmp_dir/config" "$tmp_dir/output" "$repo_dir/defaults/config.json"
[[ "$before" == "$(cksum "$tmp_dir/config/config.json")" ]]

printf 'broken\n' > "$tmp_dir/config/config.json"
prepare_state "$tmp_dir/config" "$tmp_dir/output" "$repo_dir/defaults/config.json" 2>"$tmp_dir/corrupt-error"
jq -e '.DownloadsPath == "/output"' "$tmp_dir/config/config.json" >/dev/null
compgen -G "$tmp_dir/config/config.json.corrupt-*" >/dev/null
grep -Fq 'Invalid config moved to' "$tmp_dir/corrupt-error"

if require_runtime "$tmp_dir/missing-launcher" definitely-not-a-command 2>"$tmp_dir/error"; then
  echo 'require_runtime unexpectedly succeeded' >&2
  exit 1
fi
grep -Fq 'Missing application launcher' "$tmp_dir/error"
