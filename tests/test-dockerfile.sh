#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

grep -Fq 'FROM ${BASE_IMAGE}' "$repo_dir/Dockerfile"
grep -Fq 'rm -f /opt/gdownloader/lib/runtime/portable.lock' "$repo_dir/Dockerfile"
grep -Fq 'java-options=-Duser.home=/opt/gdownloader-home' "$repo_dir/Dockerfile"
grep -Fq 'VOLUME ["/config", "/output"]' "$repo_dir/Dockerfile"
grep -Fq 'EXPOSE 5800' "$repo_dir/Dockerfile"
grep -Fq 'HEALTHCHECK' "$repo_dir/Dockerfile"
grep -Fq 'org.opencontainers.image.source="https://github.com/majindageta/gdownloader-docker"' "$repo_dir/Dockerfile"
grep -Fq 'org.opencontainers.image.url="https://github.com/majindageta/gdownloader-docker"' "$repo_dir/Dockerfile"
grep -Fq 'org.opencontainers.image.licenses="GPL-3.0-only"' "$repo_dir/Dockerfile"
grep -Eq 'add-pkg .*libxinerama1 .*libxt6 .*libxtst6' "$repo_dir/Dockerfile"
grep -Fq 'exec /opt/gdownloader/bin/GDownloader' "$repo_dir/rootfs/startapp.sh"
grep -Fq '/opt/base/sbin/su-exec app' "$repo_dir/rootfs/etc/cont-init.d/55-gdownloader.sh"
! grep -Fq 's6-setuidgid' "$repo_dir/rootfs/etc/cont-init.d/55-gdownloader.sh"
