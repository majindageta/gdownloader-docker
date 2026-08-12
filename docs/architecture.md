# Architecture

## Purpose and Scope

The project packages the official portable GDownloader release in a Docker image with a virtual desktop. It neither compiles nor modifies the upstream Java code and produces only a `linux/amd64` image. The original Swing GUI is displayed in the browser: the container does not replace GDownloader with a web frontend.

The image is fixed. The application and its dependencies change only when pins are updated, the image is rebuilt, and the container is recreated.

## Build Pipeline

[`versions.env`](../versions.env) contains the base image, versions, image revision, and SHA-256 checksums. [`scripts/build.sh`](../scripts/build.sh) validates that every value exists, checks digest formats, and invokes Docker with `--platform linux/amd64`. The resulting tag follows the form `gdownloader-docker:<gdownloader-version>-<image-revision>`.

The [`Dockerfile`](../Dockerfile) starts from the jlesage GUI base and installs artifacts as follows:

- downloads the `linux_portable_amd64` portable ZIP from the official GDownloader release;
- installs the standalone `yt-dlp_linux` binary from the official yt-dlp release;
- extracts `deno-x86_64-unknown-linux-gnu.zip` from the official Deno release;
- installs FFmpeg and ffprobe from the Ubuntu packages supplied by the base;
- verifies every downloaded artifact against the digest in `versions.env` before installation;
- records the effective versions in `/opt/gdownloader/COMPONENTS`.

Stable publication is separate from ordinary builds. Publishing a GitHub Release triggers [the Docker publishing workflow](../.github/workflows/publish-docker.yml). The workflow validates that a tag such as `v1.7.8-1` matches `versions.env`, builds and loads the `linux/amd64` image, runs the complete repository test suite, and only then authenticates to Docker Hub. A successful run pushes the matching versioned tag and updates `latest`; ordinary pushes to `main` publish nothing.

The public image is `majindageta/gdownloader-docker`. OCI labels identify this packaging repository as the image source, while the upstream project and redistributed component origins remain documented in the README and third-party notices.

## Image Contents

The jlesage base supplies the init system, the `app` application user, Openbox, TigerVNC, noVNC, and the HTTP server. The image adds GDownloader, yt-dlp, Deno, FFmpeg, ffprobe, `curl`, `jq`, fonts, `unzip`, and the X11 libraries required by the GUI.

gallery-dl and spotDL are not installed. The initial configuration keeps them disabled, while GDownloader prefers the included system executables for yt-dlp, Deno, and FFmpeg.

## Startup Sequence

1. The jlesage init system prepares the `app` user and graphical services.
2. [`55-gdownloader.sh`](../rootfs/etc/cont-init.d/55-gdownloader.sh) creates `/config` and `/output`, applies the base image's ownership management, and attempts to write to both paths as the `app` user.
3. The same script invokes `prepare_state` as `app` and checks the launcher, yt-dlp, Deno, FFmpeg, and ffprobe.
4. [`startapp.sh`](../rootfs/startapp.sh) replaces the current process with the official `/opt/gdownloader/bin/GDownloader` launcher.
5. Openbox selects the main window through [`main-window-selection.xml`](../rootfs/etc/openbox/main-window-selection.xml).
6. TigerVNC exposes the virtual desktop to noVNC, while the base image's HTTP server makes it available on port `5800`.

An unwritable mount or a missing required executable stops initialization with an explicit error before the GUI starts.

## Application State

The upstream release is portable because it contains `lib/runtime/portable.lock`. The build removes that file and adds the Java option `-Duser.home=/opt/gdownloader-home` to `GDownloader.cfg`.

`/opt/gdownloader-home/.gdownloader` is a symbolic link to `/config`. Configuration, logs, database, and history are therefore written to the persistent mount without changing the upstream Java code.

[`bootstrap.sh`](../rootfs/usr/local/lib/gdownloader/bootstrap.sh) uses [`defaults/config.json`](../defaults/config.json) as the config seed only when `/config/config.json` does not exist. An existing valid JSON file is preserved byte for byte. An invalid file is renamed with the suffix `config.json.corrupt-<timestamp>-<pid>` before the seed is applied.

## Persistence

`/config` contains GDownloader configuration, logs, database, and history. `/output` contains downloaded files. The two paths must be separate mounts writable by the configured identity of the `app` user.

There is no dedicated temporary volume. Any application temporary files remain an internal container responsibility or reside under `/output`, according to GDownloader behavior.

Recreating the container preserves state and downloads when the same mounts are reused. The initial seed must never overwrite a valid persistent configuration.

## GUI and Networking

The graphical path is:

```text
browser HTTP -> noVNC/WebSocket -> TigerVNC -> X11/Openbox desktop -> Swing GUI
```

The only published application port is `5800/tcp`. TigerVNC may listen internally on port `5900`, but the packaging neither declares nor publishes that port. Keyboard, pointer, and clipboard data travel through the VNC protocol; the browser displays the native GUI, not an HTML replica.

## Permissions and Identity

The jlesage base creates the `app` user using `USER_ID` and `GROUP_ID`, both optional and defaulting to `1000`. `UMASK` controls permissions on new files. Before startup, init performs a real file creation and removal test in `/config` and `/output` through `su-exec app`.

On a native Linux Docker host, numeric bind-mount ownership maps directly to UID and GID values. Docker Desktop on macOS may remap ownership of existing files when remounting a directory; tests therefore always verify identity and writability and apply some numeric assertions only on native Linux hosts.

## Health Check

The health check makes an internal HTTP request to `http://127.0.0.1:5800/`. It verifies that the noVNC web service responds, with a start period and retries suitable for GUI startup. It does not certify that GDownloader completed functional initialization or that a download succeeds.

## Networking and Security

The default deployment uses unauthenticated HTTP. It is therefore suitable only for a trusted local network and must not be published directly on the Internet. Remote access requires a VPN or a reverse proxy with authentication and TLS.

[`compose.yaml`](../compose.yaml) publishes only `5800:5800`. The operator remains responsible for firewall rules, LAN segmentation, and access to the Docker host.

## Intentional Boundaries

- Fixed image with no in-container automatic updates.
- `linux/amd64` only, with no ARM variant.
- No patches to upstream Java code.
- No alternative native web UI for the Swing GUI.
- No gallery-dl or spotDL installation.
- No persistent volumes other than `/config` and `/output`.
- No dedicated temporary volume.
- No default publication of port `5900`.
- No authentication integrated into the initial packaging.

Changing any of these boundaries requires an explicit design decision and coordinated updates to tests and documentation.

## Implementation Map

| Path | Responsibility |
| --- | --- |
| [`versions.env`](../versions.env) | Pins, image revision, and SHA-256 checksums. |
| [`scripts/build.sh`](../scripts/build.sh) | Pin validation and canonical amd64 build. |
| [`Dockerfile`](../Dockerfile) | Image assembly and contract. |
| [`defaults/config.json`](../defaults/config.json) | Config seed for the first startup. |
| [`55-gdownloader.sh`](../rootfs/etc/cont-init.d/55-gdownloader.sh) | Mount and runtime checks during init. |
| [`bootstrap.sh`](../rootfs/usr/local/lib/gdownloader/bootstrap.sh) | Safe preparation of persistent state. |
| [`startapp.sh`](../rootfs/startapp.sh) | Official launcher startup. |
| [`compose.yaml`](../compose.yaml) | Minimal Docker and Portainer deployment. |
| [`tests/`](../tests) | Static contracts, image checks, and runtime smoke tests. |
| [`docs/verification.md`](verification.md) | End-to-end evidence collected for the image. |
