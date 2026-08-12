# Docker Hub Publishing Design

**Date:** 2026-08-12

## Goal

Publish stable `linux/amd64` builds of this repository to
`majindageta/gdownloader-docker` on Docker Hub through GitHub Actions. A
published GitHub Release is the only event that may publish an image.

## Release contract

The repository continues to define the image version in `versions.env`:

```text
GDOWNLOADER_VERSION=X.Y.Z
CONTAINER_REVISION=N
```

The corresponding GitHub tag must be `vX.Y.Z-N`. The workflow removes the
leading `v` and compares the result with the values in `versions.env`. A
mismatch fails the workflow before registry login or image publication.

A successful release publishes these Docker Hub tags:

- `majindageta/gdownloader-docker:X.Y.Z-N`
- `majindageta/gdownloader-docker:latest`

Consequently, `latest` always denotes the most recently published stable
GitHub Release. Commits and ordinary pushes to `main` never update it.

## GitHub Actions workflow

The workflow runs for the `release.published` event and performs these steps:

1. Check out the released revision.
2. Read and validate `versions.env` and the release tag.
3. Configure Docker Buildx for `linux/amd64`.
4. Build and load the existing `Dockerfile` into the runner with every pinned
   build argument from `versions.env`, the local test tag, the versioned Docker
   Hub tag, the `latest` tag, and the required OCI labels.
5. Run the complete repository test suite against the loaded image.
6. Authenticate to Docker Hub with the repository configuration described
   below.
7. Push the already tested versioned and `latest` tags.

Official GitHub and Docker actions are pinned to immutable commit SHAs. Build
layers use the GitHub Actions cache. The job receives only the permissions it
needs to read repository contents.

## Credentials

Docker Hub authentication uses:

- GitHub Actions variable `DOCKERHUB_USERNAME`, set to `majindageta`.
- GitHub Actions secret `DOCKERHUB_TOKEN`, containing a dedicated Docker Hub
  personal access token with write access.

The Docker Hub password is not stored in GitHub. The token is never written to
the repository or printed by the workflow. Token creation and the two GitHub
repository settings remain manual account-owner operations.

## Repository integration

The implementation updates public deployment examples to pull
`majindageta/gdownloader-docker:1.7.8-1` instead of relying on a locally built
image. Local builds may keep their short local tag.

The Dockerfile OCI metadata identifies this packaging repository as the image
source and preserves the upstream GDownloader relationship in the README and
third-party notices. The source label is:

```text
https://github.com/majindageta/gdownloader-docker
```

## Failure behavior

- An invalid or mismatched release tag stops before Docker Hub login.
- A missing GitHub variable or secret makes authentication fail without
  exposing the credential.
- A failed download, checksum, test, or image build occurs before registry
  authentication and prevents both tags from being published.
- A failed release is corrected by fixing the repository, updating
  `versions.env` when required, and publishing a new valid release tag. Stable
  tags are not overwritten as a recovery mechanism.

## Verification

Before enabling the first release, local tests must verify the workflow
contract, tag validation, public image references, and OCI source metadata.
The complete repository test suite and `git diff --check` must pass.

After publishing `v1.7.8-1`, verification must confirm that both
`1.7.8-1` and `latest` exist on Docker Hub, resolve to the same image digest,
and report `linux/amd64` plus the expected OCI source label.

## Out of scope

- Docker Hub Automated Builds.
- Publishing on every push to `main`.
- ARM or multi-platform images.
- Publishing development, nightly, or branch tags.
- Publishing the same image to GitHub Container Registry.
