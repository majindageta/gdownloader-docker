# GDownloader Docker: Design Specification

Date: 2026-08-11
Status: design approved

## 1. Objective

Create an unofficial Docker image of GDownloader for Linux `amd64` servers that can also be deployed with Portainer. The original Java Swing GUI must be usable from a browser on the local network through noVNC, following the model of `jlesage/docker-jdownloader-2`.

The image must include GDownloader, yt-dlp, Deno, FFmpeg, and FFprobe. Application state and downloads must survive container recreation in two separate volumes.

## 2. Scope

The first version includes:

- `linux/amd64` platform;
- official portable Linux release of GDownloader;
- original GUI exposed through a browser;
- yt-dlp as the only download engine;
- Deno for the support required by yt-dlp;
- FFmpeg and FFprobe for processing and transcoding;
- persistent configuration in `/config`;
- persistent downloads in `/output`;
- a Docker Compose example compatible with Portainer;
- non-root execution with configurable UID, GID, and umask;
- a web UI health check.

The following are excluded from the first version:

- ARM architectures;
- gallery-dl and spotDL;
- a new native web UI;
- HTTPS, authentication, and Internet publication;
- regular exposure of the VNC port;
- automatic dependency updates during runtime;
- a separate temporary volume;
- compiling GDownloader from source;
- modifying GDownloader upstream source code.

## 3. Architectural Decision

The runtime image derives from the Ubuntu 24.04 variant of the v4 series of `jlesage/baseimage-gui`. Each release pins a complete base version, not a moving tag, in the Dockerfile.

The base provides:

- virtual X server;
- Openbox;
- TigerVNC;
- noVNC and an HTTP server;
- process supervision;
- management of UID, GID, umask, locale, and timezone.

The project adds:

- GDownloader under `/opt/gdownloader`;
- yt-dlp and Deno as system executables;
- FFmpeg and FFprobe;
- initial configuration suitable for the container;
- initialization and startup scripts.

The main flow is:

```text
browser on the LAN
  -> HTTP on the port published by the host
  -> noVNC / TigerVNC / Openbox
  -> GDownloader Swing GUI
  -> yt-dlp + Deno + FFmpeg
  -> /output
```

No GDownloader remote API is introduced.

## 4. Image Build

The build downloads the portable Linux `amd64` ZIP from the official GDownloader release and verifies its checksum. The portable release includes the Java runtime produced by `jpackage`, so the final image does not require a JDK.

Upstream portable mode would write state alongside the application. During the build, the relevant `portable.lock` marker is removed so `/opt/gdownloader` remains immutable and state can be redirected to the `/config` volume.

yt-dlp and Deno are downloaded at explicit versions and verified with checksums. FFmpeg and FFprobe are installed from the distribution. The effective version of each component is recorded in the image metadata or release documentation.

A publishable build does not use the `latest` URL. Updating a component requires an explicit repository change and produces a new image.

## 5. Runtime Layout

```text
/opt/gdownloader  immutable application and Java runtime
/config           persistent configuration, database, history and logs
/output           persistent downloads, partial files and cache
/tmp              ephemeral container temporary files
```

GDownloader's media cache remains under `/output/tmp`, consistent with upstream behavior. No `/temp` mount is introduced.

## 6. Initialization and Startup

Before starting the GUI, the initialization script:

1. creates `/config` and `/output` if needed;
2. applies the permission management provided by the jlesage base;
3. verifies that both directories are writable by the application user;
4. links GDownloader's Linux home directory to the `/config` volume;
5. creates the initial configuration only when it does not exist;
6. verifies the presence of GDownloader, yt-dlp, Deno, FFmpeg, and FFprobe;
7. starts the official GDownloader launcher in the virtual display.

The link between `~/.gdownloader` and `/config` may be implemented by the launcher through a dedicated JVM home or a symbolic link. The implementation choice must respect the observable contract: no persistent state may be written outside `/config`.

The initial configuration sets:

- `DownloadsPath` to `/output`;
- automatic updates disabled;
- preference for system executables;
- gallery-dl disabled;
- spotDL disabled.

An existing configuration is not overwritten. Migrations between versions remain GDownloader's responsibility.

If `config.json` is not valid JSON, the initializer renames it with a unique backup name and creates a new initial configuration. Other files present in `/config` are not removed.

## 7. Updates and Immutability

The unit of update is the Docker image:

```text
new release or new dependencies
  -> new build and new tag
  -> pull the image
  -> recreate the container
  -> reuse /config and /output
```

GDownloader uses the executables provided by the image and does not update them automatically. GDownloader's own automatic update is also disabled by the initial configuration.

Because the upstream code is not modified, the manual update command in the GUI can still force an update. This is a known limitation documented for the first version. Immutability is guaranteed during normal startup and operation, not against an update explicitly requested by the user.

## 8. Docker Contract

The documented minimum deployment requires:

- a host port published to `5800/tcp`;
- a persistent volume mounted at `/config`;
- a persistent volume mounted at `/output`.

Example:

```sh
docker run -d \
  --name=gdownloader \
  -p 5800:5800 \
  -v /docker/appdata/gdownloader:/config:rw \
  -v /home/user/Downloads:/output:rw \
  gdownloader
```

The host port can be changed freely, for example to `8080:5800`. The internal port remains `5800/tcp`.

Docker permits startup without publishing the port and can create anonymous volumes when explicit bind mounts are absent. The container does not attempt to block these cases: the port and two mappings are documented operational requirements, not artificial startup controls.

Port `5900/tcp` is not published in the default Compose configuration.

## 9. Runtime Parameters

All environment variables are optional. The standard jlesage base parameters are reused:

| Variable | Default Value | Purpose |
| --- | --- | --- |
| `USER_ID` | `1000` | Application user UID |
| `GROUP_ID` | `1000` | Application user GID |
| `UMASK` | `0022` | Default permissions for created files |
| `TZ` | `Etc/UTC` | Container timezone |
| `LANG` | `en_US.UTF-8` | Container locale |
| `DISPLAY_WIDTH` | `1920` | Virtual desktop width |
| `DISPLAY_HEIGHT` | `1080` | Virtual desktop height |

Other jlesage base features are not redefined. The initial documentation exposes only parameters useful for this use case.

The following are not configurable at runtime:

- internal paths `/config` and `/output`;
- versions of GDownloader, yt-dlp, Deno, and FFmpeg;
- enabling gallery-dl and spotDL;
- automatic updating.

## 10. Security and Networking

The first version is intended exclusively for a trusted local network:

- HTTP without TLS;
- web authentication disabled by default;
- no additional application ports;
- no host network mode;
- no additional Docker privileges required;
- non-root application process.

The README must explicitly warn against publishing the UI on the Internet. An Internet-facing deployment requires a later design with HTTPS, authentication, and a reverse proxy.

## 11. Error Handling

- If `/config` or `/output` is not writable, startup fails with a message identifying the directory and effective UID and GID.
- If a required executable is missing or not executable, startup fails before displaying the GUI.
- If `config.json` is corrupt, it is preserved as a backup and regenerated.
- If the network is unavailable, the GUI may start but downloads will not work.
- If GDownloader exits, the supervisor and Docker policy manage the lifecycle without leaving orphan processes.
- A Docker stop sends the signal to the process and waits for a clean shutdown before forcing it.

## 12. Versioning

Image tags follow this schema:

```text
<gdownloader-version>-<container-revision>
```

Example: `1.7.8-1`.

The container revision increases when the packaging or a dependency changes without changing the GDownloader version. The `latest` tag, if published in the future, is merely an alias and is not used as a build input.

## 13. Planned Repository Structure

```text
Dockerfile
compose.yaml
README.md
LICENSE
defaults/
  config.json
rootfs/
  startapp.sh
  etc/cont-init.d/
scripts/
docs/superpowers/specs/
```

Scripts under `scripts/` provide repeatable build checks and verification; they do not replace the normal Docker workflow.

## 14. Verification Strategy

A release is acceptable when it passes all the following checks:

1. successful build for `linux/amd64`;
2. verification of downloaded-artifact checksums;
3. startup with empty `/config` and `/output`;
4. positive web UI health check;
5. visible and usable GDownloader Swing GUI from the browser;
6. detection of the included yt-dlp, Deno, FFmpeg, and FFprobe versions;
7. absence of gallery-dl and spotDL without blocking errors;
8. download of a small authorized item;
9. result present under `/output` with correct properties and permissions;
10. container recreation preserving configuration, queue, and history;
11. startup and writing with a non-root UID/GID;
12. no update downloads during normal startup;
13. clean stop and restart through Docker;
14. correct diagnostic message when a volume is not writable.

## 15. Completion Criteria

The first release is complete when a user can copy the Compose example into Portainer, change the port and host paths, start the container, open the GDownloader GUI from the browser, and download through yt-dlp into `/output` without installing dependencies on the server, while preserving state and downloads after container recreation.
