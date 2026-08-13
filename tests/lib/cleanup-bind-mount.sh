#!/usr/bin/env bash
set -euo pipefail

image=${1:?image is required}
mount_root=${2:?mount root is required}

docker run --rm --entrypoint /bin/sh \
  -v "$mount_root:/cleanup" \
  "$image" -c 'chmod -R a+rwX /cleanup' >/dev/null

rm -rf "$mount_root"
