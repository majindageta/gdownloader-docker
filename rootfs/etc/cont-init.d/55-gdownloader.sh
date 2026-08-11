#!/bin/sh
set -eu

mkdir -p /config /output
take-ownership --not-recursive --skip-if-writable /config
take-ownership --not-recursive --skip-if-writable /output

verify_app_writable() {
    directory=$1
    if ! s6-setuidgid app sh -c 'probe="$1/.gdownloader-write-test-$$"; : > "$probe" && rm -f "$probe"' sh "$directory"; then
        echo "Directory is not writable by app: $directory (uid=${USER_ID:-1000}, gid=${GROUP_ID:-1000})" >&2
        exit 1
    fi
}

verify_app_writable /config
verify_app_writable /output

. /usr/local/lib/gdownloader/bootstrap.sh
s6-setuidgid app sh -c '. /usr/local/lib/gdownloader/bootstrap.sh; prepare_state /config /output /defaults/gdownloader/config.json'
require_runtime /opt/gdownloader/bin/GDownloader yt-dlp deno ffmpeg ffprobe
