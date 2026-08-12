# Maintenance and Updates

This procedure updates image components without introducing in-container automatic updates. [`versions.env`](../versions.env) is the authoritative source for pins, image revision, and checksums: the commands below read that file instead of duplicating current versions in the documentation.

## Scope and Prerequisites

You need Docker with `linux/amd64` build support, `curl`, Git, and a SHA-256 tool. Use `sha256sum` on Linux; on macOS, use `shasum -a 256` if `sha256sum` is not installed.

Before starting:

1. create a dedicated branch and verify that the worktree is clean;
2. read [`AGENTS.md`](../AGENTS.md) and [`architecture.md`](architecture.md);
3. record the image tag currently in production;
4. ensure that the previous image is still available locally or in the registry;
5. stop the container and make a consistent backup of the host directory mounted at `/config`;
6. do not move, delete, or repurpose the host directory mounted at `/output`.

An update does not change the target: all artifacts must remain compatible with `linux/amd64`.

## Approved Sources

Use only official releases and distributions:

- [GDownloader releases](https://github.com/hstr0100/GDownloader/releases);
- [yt-dlp releases](https://github.com/yt-dlp/yt-dlp/releases);
- [Deno releases](https://github.com/denoland/deno/releases);
- [jlesage/docker-baseimage-gui releases](https://github.com/jlesage/docker-baseimage-gui/releases);
- Ubuntu repositories configured by the jlesage base for FFmpeg and ffprobe.

Do not replace these artifacts with unverified mirrors. Before changing a URL, compare it with the [`Dockerfile`](../Dockerfile) and confirm that the asset name is still the one published upstream.

## Preparing New Pins

Load the current values:

```bash
source versions.env
```

Choose an official stable release for each component being updated. Change only the relevant variables in `versions.env` after downloading and verifying the correct asset.

### GDownloader

The expected asset is the portable amd64 ZIP. Temporarily set `GDOWNLOADER_VERSION` to the candidate release or substitute the value in the command:

```bash
curl -fL -o /tmp/gdownloader.zip \
  "https://github.com/hstr0100/GDownloader/releases/download/v${GDOWNLOADER_VERSION}/gdownloader-${GDOWNLOADER_VERSION}-linux_portable_amd64.zip"
sha256sum /tmp/gdownloader.zip
```

Update `GDOWNLOADER_VERSION` and `GDOWNLOADER_SHA256`. Before building, inspect the ZIP and verify that it still contains:

- `bin/GDownloader`;
- `lib/runtime/portable.lock`;
- `lib/app/GDownloader.cfg`;
- the `lib/GDownloader.png` icon.

A change to these paths requires coordinated updates to the Dockerfile and tests. Also review release notes for changes to the configuration format or Java requirements.

### yt-dlp

The approved asset is the standalone Linux binary for x86_64:

```bash
curl -fL -o /tmp/yt-dlp_linux \
  "https://github.com/yt-dlp/yt-dlp/releases/download/${YTDLP_VERSION}/yt-dlp_linux"
sha256sum /tmp/yt-dlp_linux
```

Update `YTDLP_VERSION` and `YTDLP_SHA256`. After building, verify that `/usr/local/bin/yt-dlp --version` returns exactly the selected release and that GDownloader records the system executable in its logs.

### Deno

Use only the x86_64 GNU/Linux archive:

```bash
curl -fL -o /tmp/deno.zip \
  "https://github.com/denoland/deno/releases/download/v${DENO_VERSION}/deno-x86_64-unknown-linux-gnu.zip"
sha256sum /tmp/deno.zip
```

Update `DENO_VERSION` and `DENO_SHA256`. After building, check `deno --version` and verify that the runtime reports `x86_64-unknown-linux-gnu`.

### FFmpeg and ffprobe

FFmpeg and ffprobe do not have separate pins in `versions.env`: they come from the Ubuntu packages available during the build. Their versions may change when the `BASE_IMAGE` tag is updated or when the Ubuntu repositories associated with that tag provide a different package.

Verify both after every rebuild:

```bash
source versions.env
image_tag="gdownloader-docker:${GDOWNLOADER_VERSION}-${CONTAINER_REVISION}"
docker run --rm --platform linux/amd64 --entrypoint ffmpeg "$image_tag" -version
docker run --rm --platform linux/amd64 --entrypoint ffprobe "$image_tag" -version
```

Also confirm that GDownloader finds `/usr/bin/ffmpeg` and that a small download requiring transcoding completes successfully.

### jlesage Base Image

Update `BASE_IMAGE` only to an official jlesage tag based on a compatible Ubuntu version. Read the base release notes and verify in particular:

- the init system and `cont-init.d` script order;
- availability of `add-pkg`, `take-ownership`, and `/opt/base/sbin/su-exec`;
- `USER_ID`, `GROUP_ID`, `UMASK`, `TZ`, and display-size variables;
- Openbox, TigerVNC, noVNC, nginx, and the HTTP health check;
- WebSocket/VNC clipboard behavior.

A base image change always requires the complete suite and GUI acceptance, even when other pins do not change.

## Image Revision

`CONTAINER_REVISION` distinguishes packaging revisions that retain the same GDownloader version.

- Increment it for Dockerfile, rootfs, configuration, or documentation fixes that require a new image.
- Reset it to `1` when `GDOWNLOADER_VERSION` changes, unless a different convention is explicitly approved.
- Do not use it in place of yt-dlp or Deno pins; those components retain their own version variables.

## Licenses and Notices

For every new release, compare licenses, notices, and redistributed components. Update [`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md) when a version, origin, license, or attribution obligation changes. Verify that the GDownloader license distributed in [`LICENSE`](../LICENSE) remains consistent with the upstream release.

A technically successful build does not replace this redistribution review.

## Build

First print the canonical command and inspect its platform, tag, and build arguments:

```bash
./scripts/build.sh --dry-run
```

Then build the image:

```bash
./scripts/build.sh
```

Derive the tag from the authoritative values and inspect the image:

```bash
source versions.env
image_tag="gdownloader-docker:${GDOWNLOADER_VERSION}-${CONTAINER_REVISION}"
docker image inspect "$image_tag" \
  --format '{{.Architecture}} {{json .Config.Healthcheck}}'
```

The architecture must be `amd64`, and the health check must query internal port `5800`.

## Required Verification

Run focused tests for the changed component first, followed by the complete suite:

```bash
bash tests/run.sh
git diff --check
```

Release verification must also observe the following on a fresh container:

1. the HTTP endpoint and `healthy` status;
2. the GDownloader GUI title and version;
3. absence of the welcome wizard;
4. download path `/output`;
5. automatic updates, gallery-dl, and spotDL disabled;
6. presence and versions of yt-dlp, Deno, FFmpeg, and ffprobe;
7. the noVNC clipboard;
8. completion of a small authorized download;
9. ownership and writability of produced files;
10. persistence of settings, history, and files after recreation with the same mounts.

Update [`verification.md`](verification.md) with the date, host, image ID, components, and only outcomes that were actually observed.

## Deployment

Make a new `/config` backup before recreation. Update the image tag in `compose.yaml`, the Portainer stack, or the `docker run` command without changing the host paths mapped to `/config` and `/output`.

With Compose:

```bash
docker compose up -d --force-recreate
```

Verify health, logs, and the GUI before removing the previous image. Persistent data must not be copied into the image or replaced during deployment.

## Publishing a Stable Image

Stable images are published by [the GitHub Actions workflow](../.github/workflows/publish-docker.yml), not by an ordinary push to `main`. Before publishing, ensure the GitHub repository has variable `DOCKERHUB_USERNAME` set to `majindageta` and secret `DOCKERHUB_TOKEN` set to a dedicated Docker Hub token with Read & Write permission. Never store that token in this repository.

Use this release sequence:

1. update pins, checksums, notices, tests, and documentation on a branch;
2. run `bash tests/run.sh` and `git diff --check`;
3. merge the verified commit into `main` and push it;
4. source `versions.env` and derive `release_version="${GDOWNLOADER_VERSION}-${CONTAINER_REVISION}"`;
5. create GitHub tag `v${release_version}` on the verified `main` commit;
6. publish the GitHub Release for that tag once;
7. wait for the **Publish Docker image** workflow to succeed;
8. verify `majindageta/gdownloader-docker:${release_version}` and `majindageta/gdownloader-docker:latest` resolve to the same digest and report `linux/amd64`.

The workflow rejects a tag that does not match `versions.env`, tests the loaded image before registry login, and pushes only the versioned tag plus `latest`. Do not recover from a failed release by moving or overwriting an existing stable tag; correct the repository and publish a new release version.

## Rollback

Keep the previous image tag at least until verification is complete. If a regression occurs:

1. stop and remove only the new container;
2. restore the previous tag in the command or stack;
3. recreate the container using the same `/config` and `/output` mounts;
4. verify health, GUI, history, and access to downloads;
5. restore the `/config` backup only if the new version changed its format incompatibly.

Do not delete `/output` during a rollback. If `/config` must be restored, first retain a copy of the newest state for analysis.

## Completing the Update

Update the README, notices, glossary, or architecture only when the corresponding contract changes. Commit pins, checksums, tests, and any related documentation together. Before delivery, confirm that the worktree is clean and that the new tag can be rebuilt from the checkout.
