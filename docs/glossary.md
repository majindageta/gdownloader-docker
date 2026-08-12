# Glossary

This document defines the repository's canonical vocabulary. The definitions apply to this Docker packaging and may be more specific than the general use of the same terms.

## Upstream

The original project or distributor from which an artifact originates. The application upstream is [`hstr0100/GDownloader`](https://github.com/hstr0100/GDownloader); yt-dlp, Deno, jlesage, and Ubuntu are separate upstreams for their respective components. This repository is not affiliated with those upstreams and does not modify GDownloader's Java code.

## Fixed Image

An image in which the application and dependencies remain unchanged until a new build. This does not mean that container data is immutable: `/config` and `/output` remain persistent. Updating components inside an existing container is the opposite model and is excluded from this project.

## Portable Mode

The upstream distribution mode that stores state alongside the application and is enabled by `portable.lock`. The packaging removes that file because state must live in `/config`, separate from the image binaries.

## jlesage Base Image

The base Docker image that provides the init system, the `app` user, Openbox, TigerVNC, noVNC, and the HTTP server. This project adds GDownloader and its dependencies on top of that infrastructure without reimplementing the graphical stack.

## noVNC

An HTML5 VNC client that runs in a browser and communicates through WebSocket. In this project it carries the original Swing GUI running in the container; it is neither a native web UI nor a rewrite of GDownloader.

## Virtual Desktop

The X11 display inside the container on which Openbox arranges windows and GDownloader draws its interface. TigerVNC captures this display and noVNC makes it interactive in the browser.

## Bootstrap

Preparation performed before the application starts. It includes checking mount writability, creating or validating configuration, and verifying required executables. It is implemented by [`55-gdownloader.sh`](../rootfs/etc/cont-init.d/55-gdownloader.sh) and [`bootstrap.sh`](../rootfs/usr/local/lib/gdownloader/bootstrap.sh).

## Config Seed

The initial configuration in [`defaults/config.json`](../defaults/config.json). It is copied to `/config/config.json` only when a valid configuration does not already exist; it is not a template reapplied at every startup.

## Persistent State

Data that survives container removal and recreation. For GDownloader this includes configuration, logs, database, and history under `/config`, as well as downloaded files under `/output`.

## Bind Mount

An explicit mapping between a host directory and a container path, for example `/docker/appdata/gdownloader:/config`. Ownership and permissions depend on the host filesystem and the UID/GID values used in the container.

## Volume

Docker's general term for persistent storage mounted in a container. It may mean a Docker-managed volume or, operationally, a bind mount. The example deployment uses bind mounts because the operator selects explicit host paths.

## `/config`

The persistent destination for GDownloader configuration, logs, database, and history. The internal `~/.gdownloader` path is redirected here. An existing valid `config.json` must not be overwritten.

## `/output`

The persistent destination for downloaded files. It must be separate from `/config` and writable by the application user. It is not a temporary directory.

## System Executable

A program already provided by the image and found through `PATH`. GDownloader is configured to prefer the system executables for yt-dlp, Deno, and FFmpeg over downloads managed internally by the application.

## Pin

A version explicitly fixed in [`versions.env`](../versions.env), together with its checksum when the component is downloaded as an artifact. The pin determines which release enters the build; it does not identify packaging-only revisions.

## SHA-256 Checksum

The cryptographic digest used to verify an artifact's integrity and reproducibility before installation. Expected checksums are stored in `versions.env`, and the build fails when downloaded bytes do not match.

## Image Revision

The `CONTAINER_REVISION` number that distinguishes packaging revisions built with the same GDownloader version. Together with the application version it forms the image tag, but it does not replace individual component pins.

## Health Check

The periodic check that requests the internal HTTP page on port `5800`. It proves that the web service responds; by itself it does not prove that the GUI is ready, external tools work, or a download can complete.

## Smoke Test

A short runtime test that starts a real container and verifies the essential contract: HTTP service, application initialization, configuration, identity, writability, persistence, and rejection of invalid mounts. It is broader than a health check and narrower than manual GUI acceptance.
