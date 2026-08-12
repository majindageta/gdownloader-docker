# End-to-End Verification

Verification date: August 11, 2026.

## Environment

- Host: macOS `arm64` with Docker Desktop.
- Docker client/server: `20.10.22/arm64`.
- Verified image: `gdownloader-docker:1.7.8-1`.
- Image ID: `sha256:585cae5dfaec8a42d46351e0e28bb0a20298a93c25ec71a1e50b3a5928e79f8b`.
- Image-declared architecture: `amd64`.
- Architecture observed in the container: `x86_64` (Docker Desktop emulation).
- Configured health check: HTTP request to `127.0.0.1:5800`, 30 s interval, 5 s timeout, 3 retries, 30 s start period.

The container was published exclusively on `127.0.0.1:5800` and started with two separate bind mounts:

```text
/tmp/gdownloader-verification.9hjQEU/config -> /config
/tmp/gdownloader-verification.9hjQEU/output -> /output
```

Verification data was retained at the host path shown above; the `gdownloader-verification` container was removed afterward.

## Observed Components

The image's `/opt/gdownloader/COMPONENTS` file reports:

```text
GDownloader 1.7.8
2026.07.04
deno 2.9.5 (stable, release, x86_64-unknown-linux-gnu)
ffmpeg version 6.1.1-3ubuntu5 Copyright (c) 2000-2023 the FFmpeg developers
```

During startup, GDownloader found `/usr/local/bin/yt-dlp`, `/usr/local/bin/deno`, and `/usr/bin/ffmpeg`. Logs also confirmed disabled automatic updates and unsupported/absent gallery-dl and spotDL updaters.

## GUI Verification

The original Swing GUI was opened in a browser through noVNC. The following were observed:

- title `GDownloader v1.7.8`;
- no initial setup wizard;
- download directory `/output`;
- automatic updates disabled;
- gallery-dl and spotDL disabled;
- final download status `Complete`.

A temporary screenshot was captured but is not included in the repository.

The noVNC Clipboard field accepted text during automation. Synthetic browser events did not produce an observable transfer, so transport was verified independently through the same `/websockify` WebSocket endpoint: the RFB `ClientCutText` message containing `gdownloader-novnc-clipboard-proof-20260811` was read unchanged from the session's X11 clipboard. The noVNC/TigerVNC clipboard path was therefore operational. To complete application acceptance, the media URL was set in the X11 clipboard and captured through the GUI's `+` button.

## Authorized Download

On the verification date, the yt-dlp video specified in the plan, `https://www.youtube.com/watch?v=BaW_jenozKc`, returned `Video unavailable` even when invoked directly with the included yt-dlp version. It was not counted as a passing test.

As an authorized alternative, FFmpeg generated a local two-second 320x180 media file, temporarily served only by the container at:

```text
http://127.0.0.1:5800/verification-sample.mp4
```

The URL was added and started through the GUI. The flow passed through `Queued`, `Transcoding`, and `Complete`, producing:

```text
/output/verification-sample (320kbps).mp3  83735 byte
/output/verification-sample (NA).mp4       26795 byte
```

Before recreation, both files were reported by the container as `uid=1000`, `gid=1000`, mode `-rw-r--r--`.

## Recreation and Persistence

The container was stopped, removed, and recreated from the same image using the same mounts. After the new startup, the following were observed:

- the HTTP endpoint was reachable again;
- Docker status was `running` and `healthy`;
- configuration still pointed to `/output`, with automatic updates, gallery-dl, and spotDL disabled;
- log entry `Successfully restored 1 downloads`;
- the completed entry was visible in the GUI again;
- both files remained in `/output` with the same sizes;
- application user `uid=1000(app) gid=1000(app)` and a successful `/output` write test producing a `1000:1000` file.

Docker Desktop on macOS remapped the two existing files to `0:0` when the bind mount was next exposed inside the container. Persistent directories and new files created as `app` were instead `1000:1000`. For this reason, the automated test applies the numeric assertion to persisted files only on native Linux Docker hosts.

## Verified Commands

The following checks returned status 0 in the described environment:

```text
curl -fsS http://127.0.0.1:5800/
docker inspect gdownloader-verification --format '{{.State.Health.Status}}'
docker exec gdownloader-verification jq -e . /config/config.json
docker exec gdownloader-verification /opt/base/sbin/su-exec app sh -c ': > /output/.recreate-write-test'
docker image inspect gdownloader-docker:1.7.8-1
python3 /tmp/gdownloader-vnc-clipboard-test.py
docker exec -u app -e DISPLAY=:0 gdownloader-verification xclip -selection clipboard -t UTF8_STRING -o
```

The complete `bash tests/run.sh` suite was run immediately before this document was committed and exited with status `0`. The final `Directory is not writable by app: /output` message is the expected outcome of the negative case that verifies rejection of an unwritable volume.
