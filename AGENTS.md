# Agent Context

## Purpose

This repository builds an unofficial, fixed, and reproducible Docker image for GDownloader. The original Swing GUI is made accessible from a browser through noVNC; this project does not provide an alternative web UI.

## Reading by Task

| Task | Read First |
| --- | --- |
| Build, runtime, mount, or GUI changes | `docs/architecture.md` |
| Terminology or component names | `docs/glossary.md` |
| Updating GDownloader or dependencies | `docs/maintenance.md` |
| Publishing a stable release or configuring credentials | `docs/releasing.md` |
| Evidence for the current image | `docs/verification.md` |
| Docker or Portainer installation | `README.md` |

## Non-Negotiable Constraints

- The target is exclusively `linux/amd64`; do not add ARM support.
- The original Swing GUI remains accessible through noVNC on internal port `5800`.
- The image is fixed: updates require rebuilding the image and recreating the container.
- Included components are GDownloader, yt-dlp, Deno, FFmpeg, and ffprobe.
- gallery-dl and spotDL must not be installed and remain disabled.
- Only `/config` and `/output` persist; do not add a temporary volume.
- Do not publish VNC port `5900` by default.
- The unauthenticated UI is intended only for a trusted local network.
- Do not overwrite an existing valid `/config/config.json`.
- Automatic updates remain disabled.
- Runtime variables remain optional and compatible with jlesage defaults.

ARM support, in-container automatic updates, integrated authentication, new downloaders, additional volumes, or patches to the upstream Java code require a new explicit design decision.

## Authoritative Sources

- `versions.env`: versions, image revision, and checksums.
- `Dockerfile` and `scripts/build.sh`: image composition and build.
- `defaults/config.json`: initial configuration.
- `rootfs/etc/cont-init.d/55-gdownloader.sh`: mount initialization.
- `rootfs/usr/local/lib/gdownloader/bootstrap.sh`: state preparation.
- `rootfs/startapp.sh`: GUI startup.
- `compose.yaml`: minimal deployment contract.
- `docs/releasing.md`: release publication and credential procedure.
- `tests/` and `docs/verification.md`: verified behavior.
- `LICENSE` and `THIRD_PARTY_NOTICES.md`: licenses for distributed components.

## Workflow

1. Read this file and the relevant specialist document.
2. Check authoritative files before changing examples or explanations.
3. Write or update the test that represents the changed contract first.
4. Preserve user changes and limit the change to the requested scope.
5. Run the focused test, then `bash tests/run.sh` before declaring the work complete.
6. Run `git diff --check` and inspect `git status --short` before committing.

## Essential Commands

```bash
./scripts/build.sh --dry-run
./scripts/build.sh
bash tests/test-docs.sh
bash tests/run.sh
git diff --check
```
