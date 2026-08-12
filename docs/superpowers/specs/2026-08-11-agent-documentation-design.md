# Project Documentation for Agents: Design Specification

Date: August 11, 2026
Status: Approved for planning

## 1. Objective

Make the repository understandable and modifiable by future agents without forcing them to reconstruct decisions, terminology, and procedures from code or conversation history.

The documentation must also serve human developers, while maintaining two distinct paths:

- `README.md` remains focused on installation and container management;
- `AGENTS.md` guides repository work and routes readers to specialist documents.

## 2. Principles

The solution adopts a documentation-routing model. `AGENTS.md` contains the minimum context every agent must know and indicates which document to read for each activity. Details are not duplicated in the router.

The binding principles are:

1. one authoritative source for each piece of information;
2. short documents with distinct responsibilities;
3. Italian for explanations and original technical terms when they avoid ambiguity;
4. references to authoritative files instead of duplicated values that can change;
5. automated checks for structure, links, and critical constraints.

## 3. Documentation Structure

### 3.1 `AGENTS.md`

This is the mandatory entry point for agents working in the repository. It must contain:

- project purpose;
- non-negotiable constraints;
- a concise map of files and responsibilities;
- a routing table to specialist documents;
- minimal build and test commands;
- modification, verification, and commit rules;
- a list of decisions requiring new design approval.

It must not become a second operator manual or duplicate the complete architecture.

### 3.2 `docs/architecture.md`

This document describes the implemented system, not its history. It must cover:

- artifact origins and the build pipeline;
- image contents;
- initialization and startup sequence;
- the relationship between noVNC, the virtual desktop, and the Swing GUI;
- management of `user.home` and application state;
- persistence of `/config` and `/output`;
- health check, permissions, and application identity;
- intentional boundaries: amd64, local network, fixed image, and no temporary volume;
- excluded dependencies and the rationale for excluding them.

The document must reference relevant implementation files without copying large portions of code.

### 3.3 `docs/glossary.md`

This document defines the project's shared vocabulary. Each entry must include:

- the canonical term;
- its definition in the context of this repository;
- an optional distinction from similar terms;
- a link to the relevant document or file when useful.

The initial core includes at least: upstream, fixed image, portable mode, jlesage base image, noVNC, virtual desktop, bootstrap, config seed, persistent state, bind mount, volume, `/config`, `/output`, system executable, pin, SHA-256 checksum, image revision, health check, and smoke test.

### 3.4 `docs/maintenance.md`

This is the technical procedure for updating included components. It must address:

1. exclusive selection of official releases;
2. identification of the correct `linux/amd64` artifacts;
3. download and calculation of SHA-256 checksums;
4. updating `versions.env` as the authoritative source;
5. review of licenses and `THIRD_PARTY_NOTICES.md`;
6. building the image through `scripts/build.sh`;
7. execution of static and runtime tests;
8. GUI acceptance, a controlled download, and persistence;
9. tag update and deployment recreation without losing mounts;
10. a rollback strategy using the previous tag.

The procedure must distinguish updates for GDownloader, yt-dlp, Deno, FFmpeg, and the jlesage base, highlighting the checks specific to each.

### 3.5 `README.md`

This document remains operator-oriented. It receives a short section named `Project Documentation` that links to architecture, glossary, maintenance, and the verification record. It does not absorb the new technical explanations.

## 4. Authoritative Sources

To limit documentation drift, each data point is read from the following authoritative source:

| Information | Authoritative Source |
| --- | --- |
| Versions, revision, and checksums | `versions.env` |
| Build and build arguments | `scripts/build.sh`, `Dockerfile` |
| Initial configuration | `defaults/config.json` |
| Mount initialization | `rootfs/etc/cont-init.d/55-gdownloader.sh` |
| State preparation | `rootfs/usr/local/lib/gdownloader/bootstrap.sh` |
| GUI startup | `rootfs/startapp.sh` |
| Deployment contract | `compose.yaml` |
| Verified behavior | `tests/` and `docs/verification.md` |
| Included licenses | `LICENSE`, `THIRD_PARTY_NOTICES.md` |

Documents may show examples, but they must clearly identify which file to update when a value changes.

## 5. Constraints to Preserve

`AGENTS.md` must make the following constraints immediately visible:

- exclusive `linux/amd64` target;
- original Swing GUI accessible from a browser through noVNC;
- fixed image, updated through rebuild and recreation;
- GDownloader, yt-dlp, Deno, FFmpeg, and ffprobe included;
- gallery-dl and spotDL not installed and disabled;
- only `/config` and `/output` as persistent mounts;
- internal web port `5800`, with VNC port `5900` not published;
- use on a trusted local network, without default application authentication;
- no overwriting of a valid persisted `config.json`;
- optional environment variables compatible with jlesage defaults;
- automatic updates disabled.

ARM support, in-container automatic updates, integrated authentication, new download dependencies, additional volumes, or changes to upstream Java code require a new explicit design decision.

## 6. Agent Usage Workflow

An agent must follow this path:

1. read `AGENTS.md`;
2. classify the activity;
3. open only the specialist documents indicated by the router;
4. inspect the authoritative files involved;
5. modify code, tests, and documentation together when a contract changes;
6. run proportionate verification and then `tests/run.sh` before completion;
7. update documents only when behavior or vocabulary has changed.

The router must prevent an operational change from requiring the historical specification or the entire original plan to be read.

## 7. Documentation Error Handling

A change must not be considered complete when it:

- introduces invalid local links;
- duplicates versions or checksums outside authoritative sources without justification;
- contradicts the constraints listed in `AGENTS.md`;
- changes a contract without updating the relevant specialist document;
- leaves placeholders, non-executable instructions, or nonexistent filenames.

When observed behavior differs from the documentation, code and tests have diagnostic value, but the discrepancy must be resolved in the same change rather than ignored.

## 8. Verification Strategy

`tests/test-docs.sh` must be extended to check at least:

- presence of the four new documentation entry points;
- links from `README.md` to specialist documents;
- routing from `AGENTS.md` to architecture, glossary, and maintenance;
- presence in `AGENTS.md` of amd64, `/config`, `/output`, port `5800`, gallery-dl, and spotDL;
- reference to `versions.env` as the authoritative source in the maintenance document;
- presence of build, checksums, tests, persistence, and rollback in the update procedure;
- absence of incomplete-work markers in the new documents.

After the documentation tests, the complete `bash tests/run.sh` suite must run because the documentation also describes contracts verified against the image.

## 9. Completion Criteria

The work is complete when:

- `AGENTS.md`, `docs/architecture.md`, `docs/glossary.md`, and `docs/maintenance.md` exist and have non-overlapping responsibilities;
- `README.md` links correctly to the new documentation;
- the maintenance procedure is executable without relying on conversation history;
- an agent can identify authoritative sources, constraints, and applicable tests starting only from `AGENTS.md`;
- `tests/test-docs.sh`, `tests/run.sh`, and `git diff --check` exit with status zero;
- the worktree is clean after the commit.
