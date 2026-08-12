# Agent Documentation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a context router for agents and separate documents for architecture, vocabulary, and project maintenance of GDownloader Docker.

**Architecture:** `AGENTS.md` provides constraints and routing, while three specialist documents maintain distinct responsibilities. `README.md` remains operator-focused and links to the new set; `tests/test-docs.sh` prevents regressions in presence, links, and critical content.

**Tech Stack:** Markdown, Bash, `grep`, `rg`, existing Docker test suite.

## Global Constraints

- Write explanations in Italian and preserve original technical terms when a translation would be ambiguous.
- Treat `versions.env` as the sole authoritative source for versions, image revision, and checksums.
- Do not duplicate the entire architecture or maintenance procedure in `AGENTS.md`.
- Preserve the exclusive target `linux/amd64`; do not introduce ARM.
- Preserve the original Swing GUI accessible from a browser through noVNC.
- Preserve the fixed image, updated through rebuild and recreation.
- Include only GDownloader, yt-dlp, Deno, FFmpeg, and ffprobe; gallery-dl and spotDL remain absent and disabled.
- Preserve only the persistent mounts `/config` and `/output`; do not introduce a temporary volume.
- Preserve internal web port `5800`; do not publish `5900` by default.
- Describe the deployment as suitable exclusively for a trusted local network, without default authentication.
- Do not change runtime code, configuration, versions, or dependencies during this documentation change.
- Work test-first, run `git diff --check` before every commit, and leave no incomplete-work markers in final documents.

---

## Planned File Map

- `AGENTS.md`: mandatory router for agents, constraints, authoritative sources, and commands.
- `docs/architecture.md`: description of the implemented system and its boundaries.
- `docs/glossary.md`: canonical project vocabulary.
- `docs/maintenance.md`: reproducible update and rollback procedure.
- `README.md`: links for developers and agents, without duplicated content.
- `tests/test-docs.sh`: automated documentation contract.

---

### Task 1: Agent Router and Architecture

**Files:**
- Create: `AGENTS.md`
- Create: `docs/architecture.md`
- Modify: `tests/test-docs.sh`

**Interfaces:**
- Consumes: current repository structure, specification constraints, and commands already present in `tests/run.sh` and `scripts/build.sh`.
- Produces: the `AGENTS.md` entry point and `docs/architecture.md` architectural source used by later tasks.

- [ ] **Step 1: Add the initial documentation contract**

Append to `tests/test-docs.sh`:

```bash
for file in AGENTS.md docs/architecture.md; do
  [[ -s "$repo_dir/$file" ]] || { echo "Missing agent documentation: $file" >&2; exit 1; }
done

for reference in docs/architecture.md docs/glossary.md docs/maintenance.md docs/verification.md; do
  grep -F "$reference" "$repo_dir/AGENTS.md"
done

for constraint in linux/amd64 noVNC /config /output 5800 gallery-dl spotDL versions.env tests/run.sh; do
  grep -F "$constraint" "$repo_dir/AGENTS.md"
done

for heading in 'Build Pipeline' 'Startup Sequence' 'Persistence' 'Networking and Security' 'Intentional Boundaries'; do
  grep -F "## $heading" "$repo_dir/docs/architecture.md"
done
```

- [ ] **Step 2: Verify the expected failure**

Run: `bash tests/test-docs.sh`

Expected: FAIL with `Missing agent documentation: AGENTS.md`.

- [ ] **Step 3: Create `AGENTS.md`**

Create a concise document with this structure and these binding contents:

```markdown
# Agent Context

## Purpose

This repository builds an unofficial, fixed, and reproducible Docker image for GDownloader. The original Swing GUI is made accessible from a browser through noVNC.

## Reading by Task

| Task | Read First |
| --- | --- |
| Build, runtime, mount, or GUI changes | `docs/architecture.md` |
| Terminology or component names | `docs/glossary.md` |
| Updating GDownloader or dependencies | `docs/maintenance.md` |
| Evidence for the current image | `docs/verification.md` |
| Docker or Portainer installation | `README.md` |

The specifications and plans under `docs/superpowers/` describe the project's history; they do not replace the operational documents listed above.

## Non-Negotiable Constraints

- Exclusive `linux/amd64` target; no ARM support.
- Original Swing GUI through noVNC on internal port `5800`.
- Fixed image: updates require rebuilding and recreation.
- Included components: GDownloader, yt-dlp, Deno, FFmpeg, and ffprobe.
- gallery-dl and spotDL must not be installed and remain disabled.
- Only `/config` and `/output` persist; do not add a temporary volume.
- Do not publish VNC port `5900` by default.
- The unauthenticated UI is intended only for a trusted local network.
- Do not overwrite an existing valid `/config/config.json`.
- Automatic updates remain disabled.
- Runtime variables remain optional and compatible with jlesage defaults.

ARM support, in-container automatic updates, integrated authentication, new downloaders, additional volumes, or patches to upstream Java code require a new explicit design decision.

## Authoritative Sources

- `versions.env`: versions, image revision, and checksums.
- `Dockerfile` and `scripts/build.sh`: image composition and build.
- `defaults/config.json`: initial configuration.
- `rootfs/etc/cont-init.d/55-gdownloader.sh`: mount initialization.
- `rootfs/usr/local/lib/gdownloader/bootstrap.sh`: state preparation.
- `rootfs/startapp.sh`: GUI startup.
- `compose.yaml`: minimal deployment contract.
- `tests/` and `docs/verification.md`: verified behavior.

## Workflow

1. Read this file and the relevant specialist document.
2. Check authoritative files before changing examples or explanations.
3. Write or update the test representing the changed contract first.
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
```

- [ ] **Step 4: Create `docs/architecture.md`**

Create the document with the following sections and describe current behavior:

```markdown
# Architecture

## Purpose and Scope

The image packages the official portable GDownloader release on the jlesage GUI base. It neither compiles nor modifies the upstream Java code and produces only a `linux/amd64` image.

## Build Pipeline

`versions.env` contains pins and SHA-256 checksums. `scripts/build.sh` validates the values and invokes Docker with `--platform linux/amd64`. The `Dockerfile` downloads official artifacts, verifies checksums before installation, installs Ubuntu packages, and records versions in `/opt/gdownloader/COMPONENTS`.

Document the portable GDownloader archive, standalone yt-dlp binary, amd64 Deno archive, and FFmpeg/ffprobe from Ubuntu separately.

## Image Contents

List the jlesage/noVNC base, GDownloader, yt-dlp, Deno, FFmpeg/ffprobe, `jq`, fonts, and X11 libraries. Explain that gallery-dl and spotDL are not installed.

## Startup Sequence

Describe, in order: jlesage init, `55-gdownloader.sh`, writability checks as `app`, `prepare_state`, executable checks, `startapp.sh`, Openbox desktop, Swing GUI, and the noVNC HTTP service.

## Application State

Explain removal of `portable.lock`, the Java option `-Duser.home=/opt/gdownloader-home`, and the link `/opt/gdownloader-home/.gdownloader -> /config`. Describe the initial seed, preservation of valid JSON, and backup of corrupt configuration.

## Persistence

Define `/config` as configuration, logs, database, and history; `/output` as the download destination. Clarify that there is no temporary volume and bind mounts must remain separate.

## GUI and Networking

Describe the browser HTTP -> noVNC/WebSocket -> TigerVNC/Openbox -> Swing GUI path. The only published port is `5800`; `5900` remains internal. Clipboard and input travel through the VNC protocol.

## Permissions and Identity

Describe `USER_ID`, `GROUP_ID`, `UMASK`, the `app` user, startup write checks, and observable ownership differences between Docker Desktop bind mounts and native Linux.

## Health Check

Describe the internal HTTP request to `127.0.0.1:5800`, its purpose, and the fact that it does not certify a successful download.

## Networking and Security

State that unauthenticated HTTP is acceptable only on a trusted LAN; use a VPN or a reverse proxy with authentication and TLS for remote access.

## Intentional Boundaries

Reiterate fixed image, amd64, no automatic updates, no ARM, no temporary volume, no published port 5900, no upstream Java patches, and no gallery-dl/spotDL dependencies.

## Implementation Map

Link `versions.env`, `scripts/build.sh`, `Dockerfile`, `defaults/config.json`, the three scripts under `rootfs/`, `compose.yaml`, `tests/`, and `docs/verification.md`, identifying each responsibility in one sentence.
```

Turn each section's internal instructions into final prose; leave no imperative phrases or editorial notes.

- [ ] **Step 5: Verify the documents**

Run:

```bash
bash tests/test-docs.sh
git diff --check
```

Expected: both exit with status 0.

- [ ] **Step 6: Commit**

```bash
git add AGENTS.md docs/architecture.md tests/test-docs.sh
git commit -m "docs: add agent context and architecture guide"
```

---

### Task 2: Canonical Glossary

**Files:**
- Create: `docs/glossary.md`
- Modify: `tests/test-docs.sh`

**Interfaces:**
- Consumes: terminology and boundaries defined by `AGENTS.md` and `docs/architecture.md`.
- Produces: canonical definitions referenced by agents, maintainers, and future documents.

- [ ] **Step 1: Add the vocabulary test**

Append to `tests/test-docs.sh`:

```bash
[[ -s "$repo_dir/docs/glossary.md" ]] || { echo 'Missing docs/glossary.md' >&2; exit 1; }
for term in \
  '## Upstream' \
  '## Fixed Image' \
  '## Portable Mode' \
  '## jlesage Base Image' \
  '## noVNC' \
  '## Virtual Desktop' \
  '## Bootstrap' \
  '## Config Seed' \
  '## Persistent State' \
  '## Bind Mount' \
  '## Volume' \
  '## `/config`' \
  '## `/output`' \
  '## System Executable' \
  '## Pin' \
  '## SHA-256 Checksum' \
  '## Image Revision' \
  '## Health Check' \
  '## Smoke Test'; do
  grep -F "$term" "$repo_dir/docs/glossary.md"
done
```

- [ ] **Step 2: Verify the expected failure**

Run: `bash tests/test-docs.sh`

Expected: FAIL with `Missing docs/glossary.md`.

- [ ] **Step 3: Create `docs/glossary.md`**

Create `# Glossary` and a `##` section for each term in the test. Use these definitions, expanding only with relevant links:

| Term | Required Definition |
| --- | --- |
| Upstream | Original project or distributor from which an artifact originates; for GDownloader it is `hstr0100/GDownloader`. |
| Fixed Image | An image in which the application and dependencies remain unchanged until a new build. |
| Portable Mode | Upstream mode enabled by `portable.lock`; it is removed because state must live in `/config`. |
| jlesage Base Image | An image providing init, the `app` user, Openbox, TigerVNC, noVNC, and an HTTP server. |
| noVNC | An HTML5 VNC client accessible from the browser; it is not a web rewrite of GDownloader. |
| Virtual Desktop | An X11 display in the container on which the Swing GUI runs. |
| Bootstrap | Preparation and validation of mounts, configuration, and executables before startup. |
| Config Seed | `defaults/config.json`, copied only when a valid persistent configuration does not exist. |
| Persistent State | Configuration, logs, database, and history preserved beyond the container lifetime. |
| Bind Mount | An explicit mapping between a host directory and container path. |
| Volume | Docker's general term for persistent storage; it does not necessarily imply a bind mount. |
| `/config` | Persistent destination for GDownloader state. |
| `/output` | Persistent destination for downloaded files. |
| System Executable | A program supplied in the image and found through `PATH`, preferred over an internal application download. |
| Pin | A version value fixed in `versions.env`. |
| SHA-256 Checksum | A digest verified before installation to ensure integrity and reproducibility. |
| Image Revision | A number distinguishing packaging revisions with the same GDownloader version. |
| Health Check | An HTTP check of internal web-service reachability. |
| Smoke Test | A short runtime test that starts a container and verifies the essential contract. |

Each definition must explain the term in the repository context and distinguish at least `bind mount` from `volume`, `noVNC` from a native web UI, `health check` from a functional download, and `pin` from `image revision`.

- [ ] **Step 4: Verify and commit**

Run:

```bash
bash tests/test-docs.sh
git diff --check
```

Expected: both exit with status 0.

Commit:

```bash
git add docs/glossary.md tests/test-docs.sh
git commit -m "docs: add project glossary"
```

---

### Task 3: Maintenance Procedure and README Index

**Files:**
- Create: `docs/maintenance.md`
- Modify: `README.md`
- Modify: `tests/test-docs.sh`

**Interfaces:**
- Consumes: `versions.env`, URLs in the `Dockerfile`, `scripts/build.sh`, the `tests/run.sh` test suite, and the persistence contract.
- Produces: a complete update/rollback procedure and public links from the README.

- [ ] **Step 1: Add maintenance and link tests**

Append to `tests/test-docs.sh`:

```bash
[[ -s "$repo_dir/docs/maintenance.md" ]] || { echo 'Missing docs/maintenance.md' >&2; exit 1; }

for reference in \
  'docs/architecture.md' \
  'docs/glossary.md' \
  'docs/maintenance.md' \
  'docs/verification.md'; do
  grep -F "$reference" "$repo_dir/README.md"
done

for requirement in \
  versions.env \
  linux/amd64 \
  sha256sum \
  scripts/build.sh \
  tests/run.sh \
  THIRD_PARTY_NOTICES.md \
  /config \
  /output \
  rollback; do
  grep -Fi "$requirement" "$repo_dir/docs/maintenance.md"
done

for component in GDownloader yt-dlp Deno FFmpeg jlesage; do
  grep -F "$component" "$repo_dir/docs/maintenance.md"
done

for file in AGENTS.md docs/architecture.md docs/glossary.md docs/maintenance.md; do
  if rg -n '\b(TO[D]O|TB[D]|FIX[M]E)\b' "$repo_dir/$file"; then
    echo "Incomplete marker found in $file" >&2
    exit 1
  fi
done
```

- [ ] **Step 2: Verify the expected failure**

Run: `bash tests/test-docs.sh`

Expected: FAIL with `Missing docs/maintenance.md`.

- [ ] **Step 3: Create the maintenance procedure**

Create `docs/maintenance.md` with this executable sequence:

1. **Scope and prerequisites:** Docker with `linux/amd64` build support, `curl`, `sha256sum` (or `shasum -a 256` on macOS), a clean worktree, a `/config` backup, and no changes to data in `/output`.
2. **Official sources:** GitHub releases for GDownloader, yt-dlp, and Deno; jlesage tags for the base; Ubuntu packages for FFmpeg. Prohibit unverified mirrors.
3. **Preparation:** create a dedicated branch, read `versions.env`, record the current image tag, and build the previous image before changing pins if it is not already available.
4. **GDownloader:** download `gdownloader-${version}-linux_portable_amd64.zip`, calculate SHA-256, update `GDOWNLOADER_VERSION` and `GDOWNLOADER_SHA256`, and check the launcher name and `lib/runtime`/`lib/app` structure.
5. **yt-dlp:** download `yt-dlp_linux`, calculate SHA-256, update `YTDLP_VERSION` and `YTDLP_SHA256`, and verify `yt-dlp --version` in the container.
6. **Deno:** download `deno-x86_64-unknown-linux-gnu.zip`, calculate SHA-256, update `DENO_VERSION` and `DENO_SHA256`, and verify `deno --version` and x86_64 architecture.
7. **FFmpeg and base:** explain that FFmpeg comes from Ubuntu; update `BASE_IMAGE` only to a compatible jlesage Ubuntu tag, then verify `ffmpeg` and `ffprobe` versions, the init script, and noVNC.
8. **Revision:** increment `CONTAINER_REVISION` for packaging-only changes; reset it to `1` when GDownloader changes unless a different convention is explicitly approved.
9. **Licenses:** compare licenses and distributed dependencies and update `THIRD_PARTY_NOTICES.md` if a release, license, or origin changes.
10. **Build:** run `./scripts/build.sh --dry-run`, inspect tags and build arguments, then run `./scripts/build.sh`.
11. **Verification:** run `bash tests/run.sh`, `git diff --check`, inspect architecture and the health check, open the GUI, check version and settings, complete a small authorized download, and recreate the container with the same mounts.
12. **Deployment:** back up `/config`, update the tag in Compose or Portainer, and recreate without changing the host paths for `/config` and `/output`.
13. **Rollback:** stop the new container, restore the previous image tag, and recreate with the same mounts; restore the `/config` backup only if the new version changed the format incompatibly.
14. **Completion:** update the README, verification record, and notices when necessary, then commit pins, documentation, and tests together.

Include these concrete commands, using task-specific variable names and without overwriting `HOME`:

```bash
source versions.env
curl -fL -o /tmp/gdownloader.zip \
  "https://github.com/hstr0100/GDownloader/releases/download/v${GDOWNLOADER_VERSION}/gdownloader-${GDOWNLOADER_VERSION}-linux_portable_amd64.zip"
sha256sum /tmp/gdownloader.zip

curl -fL -o /tmp/yt-dlp_linux \
  "https://github.com/yt-dlp/yt-dlp/releases/download/${YTDLP_VERSION}/yt-dlp_linux"
sha256sum /tmp/yt-dlp_linux

curl -fL -o /tmp/deno.zip \
  "https://github.com/denoland/deno/releases/download/v${DENO_VERSION}/deno-x86_64-unknown-linux-gnu.zip"
sha256sum /tmp/deno.zip

./scripts/build.sh --dry-run
./scripts/build.sh
bash tests/run.sh
git diff --check
docker image inspect "gdownloader-docker:${GDOWNLOADER_VERSION}-${CONTAINER_REVISION}" \
  --format '{{.Architecture}} {{json .Config.Healthcheck}}'
```

Specify that values in the document are examples derived from `versions.env`, not duplicate pins to update manually.

- [ ] **Step 4: Link the documentation from the README**

Insert after the introduction in `README.md`:

```markdown
## Project Documentation

- [Architecture](docs/architecture.md): build, startup, GUI, persistence, and system boundaries.
- [Glossary](docs/glossary.md): canonical vocabulary used in the repository.
- [Maintenance](docs/maintenance.md): component updates, checksums, tests, deployment, and rollback.
- [End-to-End Verification](docs/verification.md): evidence collected for the current image.

Agents modifying the repository must start with [AGENTS.md](AGENTS.md).
```

- [ ] **Step 5: Verify the task**

Run:

```bash
bash tests/test-docs.sh
git diff --check
```

Expected: both exit with status 0 and no incomplete-work markers remain.

- [ ] **Step 6: Commit**

```bash
git add docs/maintenance.md README.md tests/test-docs.sh
git commit -m "docs: add component maintenance workflow"
```

---

### Task 4: Final Documentation Audit

**Files:**
- Verify: `AGENTS.md`
- Verify: `docs/architecture.md`
- Verify: `docs/glossary.md`
- Verify: `docs/maintenance.md`
- Verify: `README.md`
- Verify: `tests/test-docs.sh`

**Interfaces:**
- Consumes: all documents and tests produced by the previous tasks.
- Produces: conclusive evidence of consistency, valid links, and a green test suite.

- [ ] **Step 1: Check cited authoritative files**

Run:

```bash
for file in \
  versions.env \
  scripts/build.sh \
  Dockerfile \
  defaults/config.json \
  rootfs/etc/cont-init.d/55-gdownloader.sh \
  rootfs/usr/local/lib/gdownloader/bootstrap.sh \
  rootfs/startapp.sh \
  compose.yaml \
  docs/verification.md; do
  test -e "$file" || exit 1
done
```

Expected: status 0.

- [ ] **Step 2: Run the documentation test in isolation**

Run: `bash tests/test-docs.sh`

Expected: status 0.

- [ ] **Step 3: Run the complete test suite**

Run: `bash tests/run.sh`

Expected: status 0; the negative message for unwritable `/output` is expected from the smoke test.

- [ ] **Step 4: Check quality and Git status**

Run:

```bash
git diff --check
git status --short --branch
git log --oneline -4
```

Expected: no uncommitted diffs, a clean `feat/gdownloader-docker` branch, and three new documentation commits after the specification commit.

- [ ] **Step 5: Confirm readability from the router alone**

Starting from `AGENTS.md`, manually verify that all six points are referenced directly and unambiguously without consulting history:

- source of versions and checksums;
- document used for an update;
- document used to understand bootstrap and persistence;
- definition of fixed image and portable mode;
- command for the complete test;
- changes requiring a new design decision.

Expected: all six points have a direct and unambiguous reference.
