#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
output=$("$repo_dir/scripts/build.sh" --dry-run)

grep -Fq -- '--platform linux/amd64' <<<"$output"
grep -Fq -- '--tag gdownloader-docker:1.7.8-2' <<<"$output"
grep -Fq -- '--build-arg BASE_IMAGE=jlesage/baseimage-gui:ubuntu-24.04-v4.12.6' <<<"$output"
grep -Fq -- '--build-arg GDOWNLOADER_VERSION=1.7.8' <<<"$output"
grep -Fq -- '--build-arg YTDLP_VERSION=2026.07.04' <<<"$output"
grep -Fq -- '--build-arg DENO_VERSION=2.9.5' <<<"$output"
grep -Eq 'GDOWNLOADER_SHA256=[0-9a-f]{64}' <<<"$output"
grep -Eq 'YTDLP_SHA256=[0-9a-f]{64}' <<<"$output"
grep -Eq 'DENO_SHA256=[0-9a-f]{64}' <<<"$output"
