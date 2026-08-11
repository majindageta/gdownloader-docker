# GDownloader Docker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a fixed `linux/amd64` Docker image that runs the official GDownloader Swing GUI through noVNC and persists configuration and downloads in separate volumes.

**Architecture:** Package the official GDownloader Linux portable ZIP on the Ubuntu 24.04 jlesage GUI base. Remove portable mode, redirect GDownloader state to `/config`, install pinned yt-dlp and Deno plus distribution FFmpeg, and expose only the noVNC HTTP service on port 5800.

**Tech Stack:** Docker/BuildKit, jlesage/baseimage-gui v4, POSIX shell, Bash, jq, curl, Java 25 jpackage runtime, yt-dlp, Deno, FFmpeg, noVNC/TigerVNC/Openbox.

## Global Constraints

- Target exactly `linux/amd64`; do not add ARM variants.
- Use the official portable release; do not compile or patch upstream Java.
- Initial pins: GDownloader `1.7.8`, yt-dlp `2026.07.04`, Deno `2.9.5`, base `jlesage/baseimage-gui:ubuntu-24.04-v4.12.6`.
- Install neither gallery-dl nor spotDL and disable both in initial configuration.
- Persist only `/config` and `/output`; do not add a temp volume.
- Use `5800/tcp` for the web UI; do not publish `5900/tcp` by default.
- Target a trusted LAN using HTTP without authentication.
- Keep all environment variables optional and retain approved jlesage defaults.
- Never overwrite a valid existing `/config/config.json`.
- Disable automatic updates; document that upstream manual update remains possible.
- Write tests first, commit frequently, and run `git diff --check` before commits.

---

## Planned File Map

- `versions.env`: pinned versions, image revision, and SHA-256 digests.
- `scripts/build.sh`: validates pins and runs the canonical Docker build.
- `defaults/config.json`: first-run container configuration.
- `rootfs/usr/local/lib/gdownloader/bootstrap.sh`: testable state functions.
- `rootfs/etc/cont-init.d/55-gdownloader.sh`: jlesage initialization adapter.
- `rootfs/startapp.sh`: official launcher entry point.
- `rootfs/etc/openbox/main-window-selection.xml`: main-window selector.
- `Dockerfile`: verified downloads and runtime image assembly.
- `.dockerignore`: narrow build context.
- `compose.yaml`: Portainer-compatible minimal deployment.
- `tests/*.sh`: unit, image-contract, smoke, and documentation tests.
- `README.md`, `LICENSE`, `THIRD_PARTY_NOTICES.md`: operator and licensing docs.

---

### Task 1: Pinned manifest and build wrapper

**Files:**
- Create: `versions.env`
- Create: `scripts/build.sh`
- Create: `tests/test-build-script.sh`

**Interfaces:**
- Consumes: Docker CLI and trusted assignments from `versions.env`.
- Produces: `scripts/build.sh [--dry-run]` and image tag `gdownloader-docker:${GDOWNLOADER_VERSION}-${CONTAINER_REVISION}`.

- [ ] **Step 1: Write the failing wrapper test**

Create `tests/test-build-script.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
output=$($repo_dir/scripts/build.sh --dry-run)
grep -F -- '--platform linux/amd64' <<<"$output"
grep -F -- '--tag gdownloader-docker:1.7.8-1' <<<"$output"
grep -F -- '--build-arg BASE_IMAGE=jlesage/baseimage-gui:ubuntu-24.04-v4.12.6' <<<"$output"
grep -F -- '--build-arg GDOWNLOADER_VERSION=1.7.8' <<<"$output"
grep -F -- '--build-arg YTDLP_VERSION=2026.07.04' <<<"$output"
grep -F -- '--build-arg DENO_VERSION=2.9.5' <<<"$output"
grep -Eq 'GDOWNLOADER_SHA256=[0-9a-f]{64}' <<<"$output"
grep -Eq 'YTDLP_SHA256=[0-9a-f]{64}' <<<"$output"
grep -Eq 'DENO_SHA256=[0-9a-f]{64}' <<<"$output"
```

- [ ] **Step 2: Verify the expected failure**

Run `bash tests/test-build-script.sh`.

Expected: FAIL because `scripts/build.sh` does not exist.

- [ ] **Step 3: Add exact version pins**

Create `versions.env`:

```bash
BASE_IMAGE=jlesage/baseimage-gui:ubuntu-24.04-v4.12.6
CONTAINER_REVISION=1
GDOWNLOADER_VERSION=1.7.8
GDOWNLOADER_SHA256=8f9bb266e2404e011fd18214a478c7a690946e289aaa9f46ce45e1fbeca7a38e
YTDLP_VERSION=2026.07.04
YTDLP_SHA256=6bbb3d314cde4febe36e5fa1d55462e29c974f63444e707871834f6d8cc210ae
DENO_VERSION=2.9.5
DENO_SHA256=8b010a3b1a4a0188a67cdb8a7a27348b2a501af78aec7fc74f2ace167368d530
```

- [ ] **Step 4: Implement the build wrapper**

Create executable `scripts/build.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo_dir/versions.env"
required=(BASE_IMAGE CONTAINER_REVISION GDOWNLOADER_VERSION GDOWNLOADER_SHA256 YTDLP_VERSION YTDLP_SHA256 DENO_VERSION DENO_SHA256)
for name in "${required[@]}"; do
  [[ -n "${!name:-}" ]] || { echo "Missing version value: $name" >&2; exit 1; }
done
for name in GDOWNLOADER_SHA256 YTDLP_SHA256 DENO_SHA256; do
  [[ "${!name}" =~ ^[0-9a-f]{64}$ ]] || { echo "Invalid SHA-256: $name" >&2; exit 1; }
done
image="gdownloader-docker:${GDOWNLOADER_VERSION}-${CONTAINER_REVISION}"
cmd=(docker build --platform linux/amd64 --tag "$image")
for name in "${required[@]}"; do cmd+=(--build-arg "$name=${!name}"); done
cmd+=("$repo_dir")
if [[ "${1:-}" == "--dry-run" ]]; then printf '%q ' "${cmd[@]}"; printf '\n'; exit 0; fi
exec "${cmd[@]}"
```

- [ ] **Step 5: Verify and commit**

```bash
chmod +x scripts/build.sh tests/test-build-script.sh
bash -n scripts/build.sh tests/test-build-script.sh
bash tests/test-build-script.sh
git diff --check
git add versions.env scripts/build.sh tests/test-build-script.sh
git commit -m "build: add pinned image version manifest"
```

---

### Task 2: Bootstrap persistent state

**Files:**
- Create: `defaults/config.json`
- Create: `rootfs/usr/local/lib/gdownloader/bootstrap.sh`
- Create: `rootfs/etc/cont-init.d/55-gdownloader.sh`
- Create: `tests/test-bootstrap.sh`

**Interfaces:**
- Consumes: `jq`, `take-ownership`, fixed production paths, and required executables.
- Produces: `prepare_state CONFIG_DIR OUTPUT_DIR DEFAULT_CONFIG` and `require_runtime APP_LAUNCHER COMMAND...`.

- [ ] **Step 1: Write failing bootstrap cases**

Create `tests/test-bootstrap.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo_dir/rootfs/usr/local/lib/gdownloader/bootstrap.sh"
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

prepare_state "$tmp_dir/config" "$tmp_dir/output" "$repo_dir/defaults/config.json"
jq -e '.DownloadsPath == "/output" and .AutomaticUpdates == false and .PreferSystemExecutables == true' "$tmp_dir/config/config.json"
jq -e '.GalleryDLSettings.Enabled == false and .SpotDLSettings.Enabled == false' "$tmp_dir/config/config.json"
printf '{"marker":"keep"}\n' > "$tmp_dir/config/config.json"
before=$(cksum "$tmp_dir/config/config.json")
prepare_state "$tmp_dir/config" "$tmp_dir/output" "$repo_dir/defaults/config.json"
[[ "$before" == "$(cksum "$tmp_dir/config/config.json")" ]]
printf 'broken\n' > "$tmp_dir/config/config.json"
prepare_state "$tmp_dir/config" "$tmp_dir/output" "$repo_dir/defaults/config.json"
jq -e '.DownloadsPath == "/output"' "$tmp_dir/config/config.json"
compgen -G "$tmp_dir/config/config.json.corrupt-*" >/dev/null

if require_runtime "$tmp_dir/missing-launcher" definitely-not-a-command 2>"$tmp_dir/error"; then
  echo 'require_runtime unexpectedly succeeded' >&2
  exit 1
fi
grep -F 'Missing application launcher' "$tmp_dir/error"
```

- [ ] **Step 2: Verify the expected failure**

Run `bash tests/test-bootstrap.sh`.

Expected: FAIL because the library does not exist.

- [ ] **Step 3: Create first-run configuration**

Create `defaults/config.json`:

```json
{
  "ConfigVersion": 38,
  "ShowWelcomeScreen": false,
  "LanguageDefined": true,
  "AutomaticUpdates": false,
  "PreferSystemExecutables": true,
  "DownloadsPath": "/output",
  "YtDlpSettings": { "PreferSystemExecutable": true },
  "GalleryDLSettings": { "Enabled": false, "PreferSystemExecutable": true },
  "SpotDLSettings": { "Enabled": false, "PreferSystemExecutable": true }
}
```

- [ ] **Step 4: Implement bootstrap functions**

Create executable `rootfs/usr/local/lib/gdownloader/bootstrap.sh`:

```sh
#!/bin/sh
prepare_state() {
    config_dir=$1; output_dir=$2; default_config=$3
    mkdir -p "$config_dir" "$output_dir"
    [ -w "$config_dir" ] || { echo "Directory is not writable: $config_dir" >&2; return 1; }
    [ -w "$output_dir" ] || { echo "Directory is not writable: $output_dir" >&2; return 1; }
    config_file="$config_dir/config.json"
    if [ -f "$config_file" ] && ! jq -e . "$config_file" >/dev/null 2>&1; then
        backup="$config_file.corrupt-$(date +%Y%m%d%H%M%S)-$$"
        mv "$config_file" "$backup"
        echo "Invalid config moved to $backup" >&2
    fi
    [ -f "$config_file" ] || cp "$default_config" "$config_file"
}
require_runtime() {
    app_launcher=$1; shift
    [ -x "$app_launcher" ] || { echo "Missing application launcher: $app_launcher" >&2; return 1; }
    for name in "$@"; do command -v "$name" >/dev/null 2>&1 || { echo "Missing runtime command: $name" >&2; return 1; }; done
}
```

- [ ] **Step 5: Add the fixed-path init adapter**

Create executable `rootfs/etc/cont-init.d/55-gdownloader.sh`:

```sh
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
```

- [ ] **Step 6: Verify and commit**

```bash
chmod +x rootfs/usr/local/lib/gdownloader/bootstrap.sh rootfs/etc/cont-init.d/55-gdownloader.sh tests/test-bootstrap.sh
jq -e . defaults/config.json >/dev/null
sh -n rootfs/usr/local/lib/gdownloader/bootstrap.sh rootfs/etc/cont-init.d/55-gdownloader.sh
bash tests/test-bootstrap.sh
git diff --check
git add defaults rootfs tests/test-bootstrap.sh
git commit -m "feat: bootstrap persistent GDownloader state"
```

---

### Task 3: Assemble the GUI image

**Files:**
- Create: `Dockerfile`
- Create: `.dockerignore`
- Create: `rootfs/startapp.sh`
- Create: `rootfs/etc/openbox/main-window-selection.xml`
- Create: `tests/test-dockerfile.sh`

**Interfaces:**
- Consumes: Task 1 build args and Task 2 rootfs/defaults.
- Produces: image `gdownloader-docker:1.7.8-1`, web port 5800, two volumes, and HTTP health check.

- [ ] **Step 1: Write the failing static contract test**

Create `tests/test-dockerfile.sh` asserting the Dockerfile contains:

```bash
#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
grep -F 'FROM ${BASE_IMAGE}' "$repo_dir/Dockerfile"
grep -F 'rm -f /opt/gdownloader/lib/runtime/portable.lock' "$repo_dir/Dockerfile"
grep -F 'java-options=-Duser.home=/opt/gdownloader-home' "$repo_dir/Dockerfile"
grep -F 'VOLUME ["/config", "/output"]' "$repo_dir/Dockerfile"
grep -F 'EXPOSE 5800' "$repo_dir/Dockerfile"
grep -F 'HEALTHCHECK' "$repo_dir/Dockerfile"
grep -F 'exec /opt/gdownloader/bin/GDownloader' "$repo_dir/rootfs/startapp.sh"
```

- [ ] **Step 2: Verify the expected failure**

Run `bash tests/test-dockerfile.sh`.

Expected: FAIL because packaging files do not exist.

- [ ] **Step 3: Add launcher and window selector**

Create `rootfs/startapp.sh`:

```sh
#!/bin/sh
set -eu
exec /opt/gdownloader/bin/GDownloader
```

Create `rootfs/etc/openbox/main-window-selection.xml`:

```xml
<Type>normal</Type>
<Title>GDownloader<Title>
```

- [ ] **Step 4: Implement Dockerfile assembly**

Create `Dockerfile` with this initial implementation:

```dockerfile
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG CONTAINER_REVISION
ARG GDOWNLOADER_VERSION
ARG GDOWNLOADER_SHA256
ARG YTDLP_VERSION
ARG YTDLP_SHA256
ARG DENO_VERSION
ARG DENO_SHA256

RUN add-pkg ca-certificates curl ffmpeg fonts-dejavu-core jq libxkbcommon-x11-0 unzip && \
    mkdir -p /opt/gdownloader /opt/gdownloader-home /defaults/gdownloader && \
    ln -s /config /opt/gdownloader-home/.gdownloader && \
    curl -fsSL -o /tmp/gdownloader.zip \
      "https://github.com/hstr0100/GDownloader/releases/download/v${GDOWNLOADER_VERSION}/gdownloader-${GDOWNLOADER_VERSION}-linux_portable_amd64.zip" && \
    echo "${GDOWNLOADER_SHA256}  /tmp/gdownloader.zip" | sha256sum -c - && \
    unzip -q /tmp/gdownloader.zip -d /opt/gdownloader && \
    rm -f /opt/gdownloader/lib/runtime/portable.lock && \
    printf '\njava-options=-Duser.home=/opt/gdownloader-home\n' >> /opt/gdownloader/lib/app/GDownloader.cfg && \
    curl -fsSL -o /usr/local/bin/yt-dlp \
      "https://github.com/yt-dlp/yt-dlp/releases/download/${YTDLP_VERSION}/yt-dlp_linux" && \
    echo "${YTDLP_SHA256}  /usr/local/bin/yt-dlp" | sha256sum -c - && \
    curl -fsSL -o /tmp/deno.zip \
      "https://github.com/denoland/deno/releases/download/v${DENO_VERSION}/deno-x86_64-unknown-linux-gnu.zip" && \
    echo "${DENO_SHA256}  /tmp/deno.zip" | sha256sum -c - && \
    unzip -q /tmp/deno.zip -d /usr/local/bin && \
    chmod 0755 /usr/local/bin/yt-dlp /usr/local/bin/deno /opt/gdownloader/bin/GDownloader && \
    APP_ICON_URL=file:///opt/gdownloader/lib/GDownloader.png && \
    install_app_icon.sh "$APP_ICON_URL" && \
    { echo "GDownloader ${GDOWNLOADER_VERSION}"; yt-dlp --version; deno --version | head -n 1; ffmpeg -version | head -n 1; } \
      > /opt/gdownloader/COMPONENTS && \
    rm -f /tmp/gdownloader.zip /tmp/deno.zip

COPY defaults/config.json /defaults/gdownloader/config.json
COPY rootfs/ /

RUN chmod 0755 /startapp.sh /etc/cont-init.d/55-gdownloader.sh \
      /usr/local/lib/gdownloader/bootstrap.sh && \
    set-cont-env APP_NAME "GDownloader" && \
    set-cont-env DOCKER_IMAGE_VERSION "${GDOWNLOADER_VERSION}-${CONTAINER_REVISION}"

VOLUME ["/config", "/output"]
EXPOSE 5800
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -fsS "http://127.0.0.1:${WEB_LISTENING_PORT:-5800}/" >/dev/null || exit 1

LABEL org.opencontainers.image.title="GDownloader" \
      org.opencontainers.image.description="Unofficial browser-accessible Docker image for GDownloader" \
      org.opencontainers.image.source="https://github.com/hstr0100/GDownloader" \
      org.opencontainers.image.version="${GDOWNLOADER_VERSION}-${CONTAINER_REVISION}"
```

If a package name or local icon URL is rejected by the pinned base, reproduce the failure, inspect `apt-cache policy` or `install_app_icon.sh`, and change only the failing integration plus its assertion.

- [ ] **Step 5: Add `.dockerignore`**

```text
.git
docs
tests
README.md
```

- [ ] **Step 6: Run static checks, then build**

```bash
chmod +x rootfs/startapp.sh tests/test-dockerfile.sh
sh -n rootfs/startapp.sh rootfs/etc/cont-init.d/55-gdownloader.sh
bash tests/test-dockerfile.sh
git diff --check
./scripts/build.sh
```

Expected: SHA checks report `OK` and Docker creates `gdownloader-docker:1.7.8-1` for `amd64`.

- [ ] **Step 7: Commit**

```bash
git add Dockerfile .dockerignore rootfs/startapp.sh rootfs/etc/openbox/main-window-selection.xml tests/test-dockerfile.sh
git commit -m "feat: package GDownloader browser GUI image"
```

---

### Task 4: Image contract and live runtime tests

**Files:**
- Create: `tests/test-image.sh`
- Create: `tests/smoke.sh`
- Create: `tests/run.sh`

**Interfaces:**
- Consumes: built image tag derived from `versions.env` and a Docker daemon.
- Produces: repeatable evidence for architecture, tools, UI health, non-root operation, persistence, and no normal self-update.

- [ ] **Step 1: Write the built-image contract test**

Create executable `tests/test-image.sh`:

```bash
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
  grep -F "java-options=-Duser.home=/opt/gdownloader-home" /opt/gdownloader/lib/app/GDownloader.cfg
  command -v yt-dlp deno ffmpeg ffprobe
  ! command -v gallery-dl
  ! command -v spotdl
  cat /opt/gdownloader/COMPONENTS
'
```

- [ ] **Step 2: Run the image test**

Run `bash tests/test-image.sh`.

Expected: PASS; architecture is `amd64`, required tools exist, optional tools are absent, and versions print.

- [ ] **Step 3: Write the live smoke test**

Create executable `tests/smoke.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo_dir/versions.env"
image="gdownloader-docker:${GDOWNLOADER_VERSION}-${CONTAINER_REVISION}"
name="gd-smoke-$$"
tmp_dir=$(mktemp -d)

cleanup() {
  docker rm -f "$name" >/dev/null 2>&1 || true
  rm -rf "$tmp_dir"
}
trap cleanup EXIT
mkdir -p "$tmp_dir/config" "$tmp_dir/output"

start_container() {
docker run -d --name "$name" \
  -e USER_ID=1000 -e GROUP_ID=1000 \
  -p 127.0.0.1::5800 \
  -v "$tmp_dir/config:/config:rw" \
  -v "$tmp_dir/output:/output:rw" \
    "$image" >/dev/null
}

wait_for_ui() {
  port=$(docker port "$name" 5800/tcp | sed 's/.*://')
  for _ in $(seq 1 120); do
    curl -fsS "http://127.0.0.1:$port/" >/dev/null && return 0
    sleep 1
  done
  docker logs "$name" >&2
  return 1
}

start_container
wait_for_ui
jq -e '.DownloadsPath == "/output" and .AutomaticUpdates == false and .PreferSystemExecutables == true' "$tmp_dir/config/config.json"
jq -e '.GalleryDLSettings.Enabled == false and .SpotDLSettings.Enabled == false' "$tmp_dir/config/config.json"
grep -F 'GDownloader is initialized' "$tmp_dir/config/logs/current.log"
! grep -F 'Starting download GDownloader' "$tmp_dir/config/logs/current.log"
docker exec "$name" sh -c 'echo persisted > /output/persistence-marker'
[[ $(docker exec "$name" stat -c '%u:%g' /output/persistence-marker) == 1000:1000 ]]

docker rm -f "$name" >/dev/null
start_container
wait_for_ui
test -f "$tmp_dir/output/persistence-marker"
jq -e '.DownloadsPath == "/output"' "$tmp_dir/config/config.json"
docker inspect --format '{{json .State.Health}}' "$name"
```

Docker Desktop may virtualize host-side ownership, so the required ownership assertion is intentionally performed inside the Linux container.

Add a second, uniquely named negative container using `-v "$tmp_dir/read-only:/output:ro"`. Wait for it to exit, assert its logs contain `Directory is not writable by app: /output (uid=1000, gid=1000)`, then remove that exact container in the trap.

- [ ] **Step 4: Add the ordered test runner**

Create executable `tests/run.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
bash "$repo_dir/tests/test-build-script.sh"
bash "$repo_dir/tests/test-bootstrap.sh"
bash "$repo_dir/tests/test-dockerfile.sh"
bash "$repo_dir/tests/test-image.sh"
bash "$repo_dir/tests/smoke.sh"
```

- [ ] **Step 5: Run all automated verification**

```bash
chmod +x tests/test-image.sh tests/smoke.sh tests/run.sh
bash tests/run.sh
git diff --check
```

Expected: all tests exit zero and the noVNC endpoint responds before and after recreation.

- [ ] **Step 6: Commit**

```bash
git add tests/test-image.sh tests/smoke.sh tests/run.sh
git commit -m "test: verify image runtime and persistence"
```

---

### Task 5: Compose, Portainer, licensing, and operator docs

**Files:**
- Create: `compose.yaml`
- Replace: `README.md`
- Create: `LICENSE`
- Create: `THIRD_PARTY_NOTICES.md`
- Create: `tests/test-docs.sh`
- Modify: `Dockerfile`
- Modify: `tests/test-image.sh`
- Modify: `tests/run.sh`

**Interfaces:**
- Consumes: image and runtime contract from Tasks 1-4.
- Produces: a copy/paste deployment requiring only host port, `/config`, and `/output` choices.

- [ ] **Step 1: Write failing documentation tests**

Create executable `tests/test-docs.sh`:

```bash
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
for name in GDownloader yt-dlp Deno FFmpeg; do grep -F "$name" "$repo_dir/THIRD_PARTY_NOTICES.md"; done
```

- [ ] **Step 2: Verify the expected failure**

Run `bash tests/test-docs.sh`.

Expected: FAIL because Compose and notices do not exist and README is incomplete.

- [ ] **Step 3: Add minimal Compose**

Create `compose.yaml`:

```yaml
services:
  gdownloader:
    image: gdownloader-docker:1.7.8-1
    container_name: gdownloader
    ports:
      - "5800:5800"
    volumes:
      - /docker/appdata/gdownloader:/config:rw
      - /home/user/Downloads:/output:rw
    restart: unless-stopped
```

Do not add optional environment variables to the minimal example.

- [ ] **Step 4: Replace README with an Italian operator guide**

Include these exact sections and commands:

- unofficial notice and scope (`linux/amd64`, yt-dlp only);
- build command `./scripts/build.sh`;
- exact `docker run` from the approved design;
- exact Compose and Portainer Stack procedure;
- URL `http://<IP-SERVER>:5800` and example `8080:5800`;
- three operational requirements: host port, `/config`, `/output`;
- optional variable table with `USER_ID=1000`, `GROUP_ID=1000`, `UMASK=0022`, `TZ=Etc/UTC`, `LANG=en_US.UTF-8`, `DISPLAY_WIDTH=1920`, `DISPLAY_HEIGHT=1080`;
- upgrade procedure that recreates with the same volumes;
- `/config` backup procedure;
- warning containing `solo nella rete locale`;
- known `aggiornamento manuale` limitation;
- troubleshooting for permissions, health, logs, and FFmpeg detection;
- exact packaged-source links.

- [ ] **Step 5: Add licensing notices**

Copy the unmodified GPL-3.0 text from `../GDownloader-main/LICENSE` into `LICENSE`. Create `THIRD_PARTY_NOTICES.md` with:

```markdown
# Third-party notices

This image redistributes unmodified binaries from:

- GDownloader 1.7.8 — GPL-3.0 — https://github.com/hstr0100/GDownloader/tree/v1.7.8
- yt-dlp 2026.07.04 — Unlicense and bundled third-party licenses — https://github.com/yt-dlp/yt-dlp/tree/2026.07.04
- Deno 2.9.5 — MIT — https://github.com/denoland/deno/tree/v2.9.5
- FFmpeg — GPL/LGPL depending on Ubuntu build options — https://ffmpeg.org/
- jlesage/baseimage-gui ubuntu-24.04-v4.12.6 — MIT and bundled licenses — https://github.com/jlesage/docker-baseimage-gui

GDownloader is an upstream project of hstr0100. This Docker packaging is unofficial.
```

- [ ] **Step 6: Include license material in the distributed image**

Add after the existing `COPY rootfs/ /` in `Dockerfile`:

```dockerfile
COPY LICENSE THIRD_PARTY_NOTICES.md /usr/share/doc/gdownloader-docker/
```

Add to the inner image assertions in `tests/test-image.sh`:

```sh
test -s /usr/share/doc/gdownloader-docker/LICENSE
test -s /usr/share/doc/gdownloader-docker/THIRD_PARTY_NOTICES.md
```

- [ ] **Step 7: Add docs test to runner, rebuild, verify, and commit**

Insert `bash "$repo_dir/tests/test-docs.sh"` before image tests in `tests/run.sh`, then run:

```bash
chmod +x tests/test-docs.sh
bash tests/test-docs.sh
./scripts/build.sh
bash tests/run.sh
git diff --check
git add compose.yaml README.md LICENSE THIRD_PARTY_NOTICES.md Dockerfile tests/test-docs.sh tests/test-image.sh tests/run.sh
git commit -m "docs: add Docker and Portainer deployment guide"
```

---

### Task 6: End-to-end GUI acceptance

**Files:**
- Create: `docs/verification.md`

**Interfaces:**
- Consumes: completed image, a Docker host, browser access, and Internet access for one authorized media test.
- Produces: recorded release evidence and a clean Git worktree.

- [ ] **Step 1: Start a fresh documented deployment**

```bash
verification_root=$(mktemp -d /tmp/gdownloader-verification.XXXXXX)
mkdir -p "$verification_root/config" "$verification_root/output"
docker run -d \
  --name=gdownloader-verification \
  -p 127.0.0.1:5800:5800 \
  -v "$verification_root/config:/config:rw" \
  -v "$verification_root/output:/output:rw" \
  gdownloader-docker:1.7.8-1
curl --retry 120 --retry-delay 1 --retry-connrefused -fsS http://127.0.0.1:5800/ >/dev/null
```

- [ ] **Step 2: Verify the browser GUI**

Open `http://127.0.0.1:5800` and observe all of:

- title contains `GDownloader v1.7.8`;
- welcome wizard is absent;
- download path is `/output`;
- automatic updates are disabled;
- gallery-dl and spotDL are disabled;
- clipboard paste works through noVNC.

Capture one screenshot as temporary evidence; do not commit it unless requested.

- [ ] **Step 3: Exercise a download through the GUI**

Paste the yt-dlp test video `https://www.youtube.com/watch?v=BaW_jenozKc`, download a small format, and verify:

```bash
find "$verification_root/output" -type f -not -path '*/tmp/*' -print
```

If that public test URL is unavailable, use another explicitly authorized small URL and record it; do not mark the test passed without a file produced by the GUI workflow.

- [ ] **Step 4: Verify recreation and persistence**

```bash
docker stop gdownloader-verification
docker rm gdownloader-verification
docker run -d \
  --name=gdownloader-verification \
  -p 127.0.0.1:5800:5800 \
  -v "$verification_root/config:/config:rw" \
  -v "$verification_root/output:/output:rw" \
  gdownloader-docker:1.7.8-1
curl --retry 120 --retry-delay 1 --retry-connrefused -fsS http://127.0.0.1:5800/ >/dev/null
```

Confirm settings/history and the downloaded file remain.

- [ ] **Step 5: Record observed evidence**

Create `docs/verification.md` containing date, host architecture, Docker version, image ID/tag, `/opt/gdownloader/COMPONENTS`, commands and exit statuses, GUI observations, media URL, persistence result, numeric ownership, health state, and full `tests/run.sh` result. Record only observed passes.

- [ ] **Step 6: Clean exact container, retain data for review**

```bash
docker rm -f gdownloader-verification
echo "Verification data retained at: $verification_root"
```

- [ ] **Step 7: Run final verification and commit evidence**

```bash
bash tests/run.sh
git diff --check
git status --short
git add docs/verification.md
git commit -m "test: record end-to-end container verification"
git status --short --branch
docker image inspect gdownloader-docker:1.7.8-1 --format '{{.Id}} {{.Architecture}} {{json .Config.Healthcheck}}'
```

Expected: clean `main`, image architecture `amd64`, configured health check, and all tests green.
