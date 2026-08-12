#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
workflow="$repo_dir/.github/workflows/publish-docker.yml"

[[ -s "$workflow" ]]
grep -Fq 'types: [published]' "$workflow"
grep -Fq 'contents: read' "$workflow"
grep -Fq 'scripts/release-version.sh "${{ github.event.release.tag_name }}"' "$workflow"
grep -Fq 'platforms: linux/amd64' "$workflow"
grep -Fq 'load: true' "$workflow"
grep -Fq 'bash tests/run.sh' "$workflow"
grep -Fq 'username: ${{ vars.DOCKERHUB_USERNAME }}' "$workflow"
grep -Fq 'password: ${{ secrets.DOCKERHUB_TOKEN }}' "$workflow"
grep -Fq '${{ vars.DOCKERHUB_USERNAME }}/gdownloader-docker:${{ steps.version.outputs.value }}' "$workflow"
grep -Fq '${{ vars.DOCKERHUB_USERNAME }}/gdownloader-docker:latest' "$workflow"

test_line=$(grep -nF 'bash tests/run.sh' "$workflow" | cut -d: -f1)
login_line=$(grep -nF 'docker/login-action@' "$workflow" | cut -d: -f1)
[[ "$test_line" -lt "$login_line" ]]

if grep -Eq 'uses: [^ ]+@v[0-9]' "$workflow"; then
  echo 'GitHub Actions must be pinned to full commit SHAs' >&2
  exit 1
fi

[[ $(grep -Ec 'uses: [^ ]+@[0-9a-f]{40}([[:space:]]|$)' "$workflow") == 4 ]]
