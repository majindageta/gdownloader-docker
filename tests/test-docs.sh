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

for file in AGENTS.md docs/architecture.md; do
  [[ -s "$repo_dir/$file" ]] || { echo "Missing agent documentation: $file" >&2; exit 1; }
done

for reference in docs/architecture.md docs/glossary.md docs/maintenance.md docs/verification.md; do
  grep -F "$reference" "$repo_dir/AGENTS.md"
done

for constraint in linux/amd64 noVNC /config /output 5800 gallery-dl spotDL versions.env tests/run.sh; do
  grep -F "$constraint" "$repo_dir/AGENTS.md"
done

for heading in 'Pipeline di build' 'Sequenza di avvio' 'Persistenza' 'Rete e sicurezza' 'Confini intenzionali'; do
  grep -F "## $heading" "$repo_dir/docs/architecture.md"
done
