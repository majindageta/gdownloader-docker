#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo_dir/versions.env"

image="gdownloader-docker:${GDOWNLOADER_VERSION}-${CONTAINER_REVISION}"

docker image inspect "$image" >/dev/null
[[ $(docker image inspect --format '{{.Architecture}}' "$image") == amd64 ]]

docker run --rm --entrypoint /bin/sh "$image" -ec '
  test -x /opt/gdownloader/bin/GDownloader
  test ! -e /opt/gdownloader/lib/runtime/portable.lock
  test -s /usr/share/doc/gdownloader-docker/LICENSE
  test -s /usr/share/doc/gdownloader-docker/THIRD_PARTY_NOTICES.md
  grep -F "java-options=-Duser.home=/opt/gdownloader-home" /opt/gdownloader/lib/app/GDownloader.cfg
  command -v yt-dlp deno ffmpeg ffprobe
  ! command -v gallery-dl
  ! command -v spotdl
  runtime_lib=/opt/gdownloader/lib/runtime/lib
  for library in \
    "$runtime_lib/libawt_xawt.so" \
    /opt/gdownloader/lib/runtime/bin/native-libs/linux/x86_64/libJNativeHook.so
  do
    missing=$(LD_LIBRARY_PATH="$runtime_lib:$runtime_lib/server" ldd "$library" | awk "/not found/")
    if [ -n "$missing" ]; then
      printf "%s\n" "$missing" >&2
      exit 1
    fi
  done
  cat /opt/gdownloader/COMPONENTS
'
