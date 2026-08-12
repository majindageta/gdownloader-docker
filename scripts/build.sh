#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=../versions.env
source "$repo_dir/versions.env"

required=(
  BASE_IMAGE
  CONTAINER_REVISION
  GDOWNLOADER_VERSION
  GDOWNLOADER_SHA256
  YTDLP_VERSION
  YTDLP_SHA256
  DENO_VERSION
  DENO_SHA256
)

for name in "${required[@]}"; do
  [[ -n "${!name:-}" ]] || {
    echo "Missing version value: $name" >&2
    exit 1
  }
done

for name in GDOWNLOADER_SHA256 YTDLP_SHA256 DENO_SHA256; do
  [[ "${!name}" =~ ^[0-9a-f]{64}$ ]] || {
    echo "Invalid SHA-256: $name" >&2
    exit 1
  }
done

image="gdownloader-docker:${GDOWNLOADER_VERSION}-${CONTAINER_REVISION}"
cmd=(docker build --platform linux/amd64 --tag "$image")
for name in "${required[@]}"; do
  cmd+=(--build-arg "$name=${!name}")
done
cmd+=("$repo_dir")

if [[ "${1:-}" == "--dry-run" ]]; then
  printf '%q ' "${cmd[@]}"
  printf '\n'
  exit 0
fi

exec "${cmd[@]}"
