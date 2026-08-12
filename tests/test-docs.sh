#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

docker compose -f "$repo_dir/compose.yaml" config >/dev/null
grep -F '5800:5800' "$repo_dir/compose.yaml"
grep -F '/config' "$repo_dir/compose.yaml"
grep -F '/output' "$repo_dir/compose.yaml"
! grep -F '5900:' "$repo_dir/compose.yaml"
public_image='majindageta/gdownloader-docker:1.7.8-1'
grep -Fq "image: $public_image" "$repo_dir/compose.yaml"
grep -Fq "$public_image" "$repo_dir/README.md"
grep -Fq 'v1.7.8-1' "$repo_dir/README.md"
grep -Fq 'DOCKERHUB_TOKEN' "$repo_dir/README.md"
grep -Fq 'DOCKERHUB_USERNAME' "$repo_dir/README.md"
grep -F 'trusted local network' "$repo_dir/README.md"
grep -F 'Portainer' "$repo_dir/README.md"
grep -F 'manual update' "$repo_dir/README.md"
for name in GDownloader yt-dlp Deno FFmpeg; do
  grep -F "$name" "$repo_dir/THIRD_PARTY_NOTICES.md"
done

for file in AGENTS.md docs/architecture.md; do
  [[ -s "$repo_dir/$file" ]] || { echo "Missing agent documentation: $file" >&2; exit 1; }
done

for reference in docs/architecture.md docs/glossary.md docs/maintenance.md docs/verification.md; do
  grep -F "$reference" "$repo_dir/AGENTS.md"
done

for constraint in linux/amd64 noVNC /config /output 5800 gallery-dl spotDL versions.env tests/run.sh; do
  grep -F "$constraint" "$repo_dir/AGENTS.md"
done

for heading in 'Build Pipeline' 'Startup Sequence' 'Persistence' 'Networking and Security' 'Intentional Boundaries'; do
  grep -F "## $heading" "$repo_dir/docs/architecture.md"
done

[[ -s "$repo_dir/docs/glossary.md" ]] || { echo 'Missing docs/glossary.md' >&2; exit 1; }
for term in \
  '## Upstream' \
  '## Fixed Image' \
  '## Portable Mode' \
  '## jlesage Base Image' \
  '## noVNC' \
  '## Virtual Desktop' \
  '## Bootstrap' \
  '## Config Seed' \
  '## Persistent State' \
  '## Bind Mount' \
  '## Volume' \
  '## `/config`' \
  '## `/output`' \
  '## System Executable' \
  '## Pin' \
  '## SHA-256 Checksum' \
  '## Image Revision' \
  '## Health Check' \
  '## Smoke Test'; do
  grep -F "$term" "$repo_dir/docs/glossary.md"
done

[[ -s "$repo_dir/docs/maintenance.md" ]] || { echo 'Missing docs/maintenance.md' >&2; exit 1; }

for reference in \
  'docs/architecture.md' \
  'docs/glossary.md' \
  'docs/maintenance.md' \
  'docs/verification.md'; do
  grep -F "$reference" "$repo_dir/README.md"
done

for requirement in \
  versions.env \
  linux/amd64 \
  sha256sum \
  scripts/build.sh \
  tests/run.sh \
  THIRD_PARTY_NOTICES.md \
  /config \
  /output \
  rollback; do
  grep -Fi "$requirement" "$repo_dir/docs/maintenance.md"
done

for component in GDownloader yt-dlp Deno FFmpeg jlesage; do
  grep -F "$component" "$repo_dir/docs/maintenance.md"
done

for file in AGENTS.md docs/architecture.md docs/glossary.md docs/maintenance.md; do
  if rg -n '\b(TO[D]O|TB[D]|FIX[M]E)\b' "$repo_dir/$file"; then
    echo "Incomplete marker found in $file" >&2
    exit 1
  fi
done
