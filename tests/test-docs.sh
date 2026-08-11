#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

docker compose -f "$repo_dir/compose.yaml" config >/dev/null
grep -F '5800:5800' "$repo_dir/compose.yaml"
grep -F '/config' "$repo_dir/compose.yaml"
grep -F '/output' "$repo_dir/compose.yaml"
! grep -F '5900:' "$repo_dir/compose.yaml"
grep -F 'solo nella rete locale' "$repo_dir/README.md"
grep -F 'Portainer' "$repo_dir/README.md"
grep -F 'aggiornamento manuale' "$repo_dir/README.md"
for name in GDownloader yt-dlp Deno FFmpeg; do
  grep -F "$name" "$repo_dir/THIRD_PARTY_NOTICES.md"
done
