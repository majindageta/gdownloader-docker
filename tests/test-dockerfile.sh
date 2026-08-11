#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

grep -Fq 'FROM ${BASE_IMAGE}' "$repo_dir/Dockerfile"
grep -Fq 'rm -f /opt/gdownloader/lib/runtime/portable.lock' "$repo_dir/Dockerfile"
grep -Fq 'java-options=-Duser.home=/opt/gdownloader-home' "$repo_dir/Dockerfile"
grep -Fq 'VOLUME ["/config", "/output"]' "$repo_dir/Dockerfile"
grep -Fq 'EXPOSE 5800' "$repo_dir/Dockerfile"
grep -Fq 'HEALTHCHECK' "$repo_dir/Dockerfile"
grep -Fq 'exec /opt/gdownloader/bin/GDownloader' "$repo_dir/rootfs/startapp.sh"
