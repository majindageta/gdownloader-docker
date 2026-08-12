# Docker Hub Publishing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish tested `linux/amd64` images to `majindageta/gdownloader-docker` when a matching GitHub Release is published.

**Architecture:** A release-only GitHub Actions workflow validates its `vX.Y.Z-N` tag against `versions.env`, builds and loads the existing Dockerfile with a local test tag plus both public tags, runs the repository suite, and authenticates only after tests pass. It then pushes the already-tested versioned and `latest` tags to Docker Hub; repository tests statically enforce this contract and public documentation uses the registry-qualified image name.

**Tech Stack:** Bash, Docker Buildx, Docker Compose, GitHub Actions, Docker Hub, OCI image labels.

## Global Constraints

- Publish only on the GitHub `release.published` event.
- GitHub release tags use `vX.Y.Z-N`; Docker Hub version tags use `X.Y.Z-N`.
- `latest` denotes only the most recently published stable GitHub Release.
- Target only `linux/amd64`; do not add ARM or multi-platform support.
- Publish `majindageta/gdownloader-docker:X.Y.Z-N` and `majindageta/gdownloader-docker:latest`.
- Validate the release tag against `GDOWNLOADER_VERSION` and `CONTAINER_REVISION` in `versions.env` before Docker Hub login.
- Run the complete test suite against the loaded image before Docker Hub login.
- Use GitHub variable `DOCKERHUB_USERNAME` and secret `DOCKERHUB_TOKEN`; never store credentials in tracked files.
- Pin every third-party GitHub Action to a full immutable commit SHA verified from its official repository.
- Preserve the fixed-image model and existing runtime, mounts, port, security boundaries, and local short build tag.

---

### Task 1: Release-tag validation contract

**Files:**
- Create: `scripts/release-version.sh`
- Create: `tests/test-release-version.sh`
- Modify: `tests/run.sh`

**Interfaces:**
- Consumes: `versions.env` containing `GDOWNLOADER_VERSION` and `CONTAINER_REVISION`; one tag argument.
- Produces: `scripts/release-version.sh TAG`, which prints `X.Y.Z-N` on stdout and exits zero only when `TAG` is exactly `v${GDOWNLOADER_VERSION}-${CONTAINER_REVISION}`.

- [ ] **Step 1: Write the failing release-version test**

Create `tests/test-release-version.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

[[ $("$repo_dir/scripts/release-version.sh" v1.7.8-1) == 1.7.8-1 ]]

for invalid in 1.7.8-1 v1.7.8 v1.7.8-2 v01.7.8-1 v1.7.8-1-extra ''; do
  if "$repo_dir/scripts/release-version.sh" "$invalid" >/dev/null 2>&1; then
    echo "Unexpectedly accepted release tag: $invalid" >&2
    exit 1
  fi
done
```

Add `bash "$repo_dir/tests/test-release-version.sh"` to `tests/run.sh` before image-dependent tests.

- [ ] **Step 2: Run the focused test to verify it fails**

Run: `bash tests/test-release-version.sh`

Expected: FAIL because `scripts/release-version.sh` does not exist.

- [ ] **Step 3: Implement strict validation**

Create `scripts/release-version.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=../versions.env
source "$repo_dir/versions.env"

tag=${1:-}
expected="v${GDOWNLOADER_VERSION}-${CONTAINER_REVISION}"

if [[ "$tag" != "$expected" ]]; then
  echo "Release tag '$tag' does not match '$expected' from versions.env" >&2
  exit 1
fi

printf '%s-%s\n' "$GDOWNLOADER_VERSION" "$CONTAINER_REVISION"
```

Make both new scripts executable with `chmod 0755`.

- [ ] **Step 4: Run focused and aggregate static tests**

Run:

```bash
bash tests/test-release-version.sh
bash tests/test-build-script.sh
git diff --check
```

Expected: all commands exit zero.

- [ ] **Step 5: Commit the validator**

```bash
git add scripts/release-version.sh tests/test-release-version.sh tests/run.sh
git commit -m "ci: validate Docker release tags"
```

---

### Task 2: Release-only Docker Hub workflow

**Files:**
- Create: `.github/workflows/publish-docker.yml`
- Create: `tests/test-publish-workflow.sh`
- Modify: `tests/run.sh`

**Interfaces:**
- Consumes: `scripts/release-version.sh "${{ github.event.release.tag_name }}"`, every variable in `versions.env`, GitHub variable `DOCKERHUB_USERNAME`, and GitHub secret `DOCKERHUB_TOKEN`.
- Produces: a tested local `gdownloader-docker:X.Y.Z-N` image and public tags `${DOCKERHUB_USERNAME}/gdownloader-docker:X.Y.Z-N` and `${DOCKERHUB_USERNAME}/gdownloader-docker:latest` pushed after successful tests.

- [ ] **Step 1: Verify immutable official Action SHAs**

Verify the selected stable release tag from each action's official GitHub repository and confirm that the peeled commit equals the recorded SHA:

```bash
git ls-remote https://github.com/actions/checkout.git 'refs/tags/v6.0.2*'
git ls-remote https://github.com/docker/setup-buildx-action.git 'refs/tags/v4*'
git ls-remote https://github.com/docker/build-push-action.git 'refs/tags/v7.2.0*'
git ls-remote https://github.com/docker/login-action.git 'refs/tags/v4.2.0*'
```

The required mappings are:

- `actions/checkout@v6.0.2` → `de0fac2e4500dabe0009e67214ff5f5447ce83dd`
- `docker/setup-buildx-action@v4.2.0` → `bb05f3f5519dd87d3ba754cc423b652a5edd6d2c`
- `docker/build-push-action@v7.2.0` → `f9f3042f7e2789586610d6e8b85c8f03e5195baf`
- `docker/login-action@v4.2.0` → `650006c6eb7dba73a995cc03b0b2d7f5ca915bee`

Stop if an official tag does not resolve to its recorded SHA. When a tag is annotated, compare with the `^{}` peeled SHA.

- [ ] **Step 2: Write the failing workflow contract test**

Create `tests/test-publish-workflow.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
workflow="$repo_dir/.github/workflows/publish-docker.yml"

[[ -s "$workflow" ]]
grep -Fq 'types: [published]' "$workflow"
grep -Fq 'contents: read' "$workflow"
grep -Fq 'scripts/release-version.sh "${{ github.event.release.tag_name }}"' "$workflow"
grep -Fq 'platforms: linux/amd64' "$workflow"
grep -Fq 'load: true' "$workflow"
grep -Fq 'bash tests/run.sh' "$workflow"
grep -Fq 'username: ${{ vars.DOCKERHUB_USERNAME }}' "$workflow"
grep -Fq 'password: ${{ secrets.DOCKERHUB_TOKEN }}' "$workflow"
grep -Fq '${{ vars.DOCKERHUB_USERNAME }}/gdownloader-docker:${{ steps.version.outputs.value }}' "$workflow"
grep -Fq '${{ vars.DOCKERHUB_USERNAME }}/gdownloader-docker:latest' "$workflow"

test_line=$(grep -nF 'bash tests/run.sh' "$workflow" | cut -d: -f1)
login_line=$(grep -nF 'docker/login-action@' "$workflow" | cut -d: -f1)
[[ "$test_line" -lt "$login_line" ]]

if grep -Eq 'uses: [^ ]+@v[0-9]' "$workflow"; then
  echo 'GitHub Actions must be pinned to full commit SHAs' >&2
  exit 1
fi

[[ $(grep -Ec 'uses: [^ ]+@[0-9a-f]{40}([[:space:]]|$)' "$workflow") == 4 ]]
```

Add `bash "$repo_dir/tests/test-publish-workflow.sh"` to `tests/run.sh` before image-dependent tests and make it executable.

- [ ] **Step 3: Run the workflow contract test to verify it fails**

Run: `bash tests/test-publish-workflow.sh`

Expected: FAIL because `.github/workflows/publish-docker.yml` does not exist.

- [ ] **Step 4: Implement the release workflow**

Create `.github/workflows/publish-docker.yml` with the four verified full SHAs:

```yaml
name: Publish Docker image

on:
  release:
    types: [published]

permissions:
  contents: read

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - name: Check out released source
        uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2

      - name: Validate release version
        id: version
        shell: bash
        run: |
          value=$(scripts/release-version.sh "${{ github.event.release.tag_name }}")
          printf 'value=%s\n' "$value" >> "$GITHUB_OUTPUT"

      - name: Load pinned build arguments
        shell: bash
        run: cat versions.env >> "$GITHUB_ENV"

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@bb05f3f5519dd87d3ba754cc423b652a5edd6d2c # v4.2.0

      - name: Build and load image
        uses: docker/build-push-action@f9f3042f7e2789586610d6e8b85c8f03e5195baf # v7.2.0
        with:
          context: .
          file: ./Dockerfile
          platforms: linux/amd64
          load: true
          push: false
          tags: |
            gdownloader-docker:${{ steps.version.outputs.value }}
            ${{ vars.DOCKERHUB_USERNAME }}/gdownloader-docker:${{ steps.version.outputs.value }}
            ${{ vars.DOCKERHUB_USERNAME }}/gdownloader-docker:latest
          build-args: |
            BASE_IMAGE=${{ env.BASE_IMAGE }}
            CONTAINER_REVISION=${{ env.CONTAINER_REVISION }}
            GDOWNLOADER_VERSION=${{ env.GDOWNLOADER_VERSION }}
            GDOWNLOADER_SHA256=${{ env.GDOWNLOADER_SHA256 }}
            YTDLP_VERSION=${{ env.YTDLP_VERSION }}
            YTDLP_SHA256=${{ env.YTDLP_SHA256 }}
            DENO_VERSION=${{ env.DENO_VERSION }}
            DENO_SHA256=${{ env.DENO_SHA256 }}
          labels: |
            org.opencontainers.image.revision=${{ github.sha }}
            org.opencontainers.image.source=https://github.com/${{ github.repository }}
            org.opencontainers.image.version=${{ steps.version.outputs.value }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Test image
        shell: bash
        run: bash tests/run.sh

      - name: Log in to Docker Hub
        uses: docker/login-action@650006c6eb7dba73a995cc03b0b2d7f5ca915bee # v4.2.0
        with:
          username: ${{ vars.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Push tested tags
        shell: bash
        run: |
          docker push "${{ vars.DOCKERHUB_USERNAME }}/gdownloader-docker:${{ steps.version.outputs.value }}"
          docker push "${{ vars.DOCKERHUB_USERNAME }}/gdownloader-docker:latest"
```

- [ ] **Step 5: Run workflow contract and YAML parsing checks**

Run:

```bash
bash tests/test-publish-workflow.sh
ruby -e 'require "yaml"; YAML.safe_load_file(".github/workflows/publish-docker.yml", aliases: true)'
git diff --check
```

Expected: all commands exit zero. If the installed Ruby YAML parser interprets the YAML 1.1 key `on` as a boolean, the syntax check may be replaced by `ruby -e 'require "yaml"; YAML.parse_file(".github/workflows/publish-docker.yml")'`, which must still exit zero.

- [ ] **Step 6: Commit the workflow**

```bash
git add .github/workflows/publish-docker.yml tests/test-publish-workflow.sh tests/run.sh
git commit -m "ci: publish stable images to Docker Hub"
```

---

### Task 3: Public image identity and deployment references

**Files:**
- Modify: `Dockerfile`
- Modify: `compose.yaml`
- Modify: `README.md`
- Modify: `docs/maintenance.md`
- Modify: `docs/architecture.md`
- Modify: `tests/test-dockerfile.sh`
- Modify: `tests/test-docs.sh`

**Interfaces:**
- Consumes: image namespace `majindageta/gdownloader-docker`, current release `1.7.8-1`, and packaging source `https://github.com/majindageta/gdownloader-docker`.
- Produces: deployable examples that pull the public image, OCI labels that identify this packaging repository, and maintenance instructions for release-triggered publication.

- [ ] **Step 1: Extend static tests with public registry expectations**

Append to `tests/test-dockerfile.sh`:

```bash
grep -Fq 'org.opencontainers.image.source="https://github.com/majindageta/gdownloader-docker"' "$repo_dir/Dockerfile"
grep -Fq 'org.opencontainers.image.url="https://github.com/majindageta/gdownloader-docker"' "$repo_dir/Dockerfile"
grep -Fq 'org.opencontainers.image.licenses="GPL-3.0-only"' "$repo_dir/Dockerfile"
```

Append to `tests/test-docs.sh`:

```bash
public_image='majindageta/gdownloader-docker:1.7.8-1'
grep -Fq "image: $public_image" "$repo_dir/compose.yaml"
grep -Fq "$public_image" "$repo_dir/README.md"
grep -Fq 'v1.7.8-1' "$repo_dir/README.md"
grep -Fq 'DOCKERHUB_TOKEN' "$repo_dir/README.md"
grep -Fq 'DOCKERHUB_USERNAME' "$repo_dir/README.md"
```

- [ ] **Step 2: Run focused tests to verify they fail**

Run:

```bash
bash tests/test-dockerfile.sh
bash tests/test-docs.sh
```

Expected: FAIL on the old upstream OCI source and short deployment image references.

- [ ] **Step 3: Update OCI labels and public deployment references**

In `Dockerfile`, replace the source label and add URL/license labels:

```dockerfile
LABEL org.opencontainers.image.title="GDownloader" \
      org.opencontainers.image.description="Unofficial browser-accessible Docker image for GDownloader" \
      org.opencontainers.image.source="https://github.com/majindageta/gdownloader-docker" \
      org.opencontainers.image.url="https://github.com/majindageta/gdownloader-docker" \
      org.opencontainers.image.licenses="GPL-3.0-only" \
      org.opencontainers.image.version="${GDOWNLOADER_VERSION}-${CONTAINER_REVISION}"
```

Change `compose.yaml` to:

```yaml
image: majindageta/gdownloader-docker:1.7.8-1
```

In `README.md`:

- Keep the local build result documented as `gdownloader-docker:1.7.8-1`.
- Use `majindageta/gdownloader-docker:1.7.8-1` in `docker run`, Compose, and Portainer deployment instructions.
- State that stable images are published from GitHub Release `v1.7.8-1`.
- Add a maintainer-only release section specifying GitHub variable `DOCKERHUB_USERNAME=majindageta`, secret `DOCKERHUB_TOKEN`, and that the token must never be committed.

In `docs/architecture.md`, describe the release-only workflow after the local build pipeline. In `docs/maintenance.md`, add the exact release sequence: update pins, run tests, merge to `main`, create matching tag `v${GDOWNLOADER_VERSION}-${CONTAINER_REVISION}`, publish the GitHub Release, and verify both Docker Hub tags.

- [ ] **Step 4: Run focused static tests**

Run:

```bash
bash tests/test-dockerfile.sh
bash tests/test-docs.sh
bash tests/test-publish-workflow.sh
git diff --check
```

Expected: all commands exit zero.

- [ ] **Step 5: Commit public image integration**

```bash
git add Dockerfile compose.yaml README.md docs/architecture.md docs/maintenance.md tests/test-dockerfile.sh tests/test-docs.sh
git commit -m "docs: use the published Docker Hub image"
```

---

### Task 4: Full local verification and credential handoff

**Files:**
- Modify only if verification exposes a defect in files from Tasks 1-3.

**Interfaces:**
- Consumes: completed workflow, validator, tests, public image references, and existing local image `gdownloader-docker:1.7.8-1`.
- Produces: verified commits ready to push plus exact manual GitHub/Docker Hub account configuration steps.

- [ ] **Step 1: Verify effective Git identity and repository state**

Run:

```bash
git var GIT_AUTHOR_IDENT
git status --short --branch
```

Expected: identity contains `12610295+majindageta@users.noreply.github.com`; only intentional implementation changes, if any, are present.

- [ ] **Step 2: Run the complete suite**

Run:

```bash
bash tests/run.sh
```

Expected: every static, image, and smoke test exits zero. The existing image must be present locally; if absent, run `./scripts/build.sh` and rerun the suite.

- [ ] **Step 3: Run final repository checks**

Run:

```bash
git diff --check
git status --short
git log -4 --format='%h %s | %an <%ae>'
```

Expected: no whitespace errors, no uncommitted implementation changes, and all new commits use the GitHub `noreply` email.

- [ ] **Step 4: Configure credentials manually without exposing them**

In Docker Hub, create a dedicated personal access token named `github-actions-gdownloader-docker` with Read & Write permission. Copy it once and do not paste it into chat or a repository file.

In GitHub repository `majindageta/gdownloader-docker`, open **Settings → Secrets and variables → Actions** and create:

- Variable: `DOCKERHUB_USERNAME` = `majindageta`
- Secret: `DOCKERHUB_TOKEN` = the Docker Hub access token

- [ ] **Step 5: Push implementation commits**

Run:

```bash
git push origin main
```

Expected: GitHub accepts the commits over the already configured SSH remote.

- [ ] **Step 6: Publish and verify the first release**

On GitHub, create tag and release `v1.7.8-1` from the verified `main` commit. Publish the release once; do not create the tag from an older commit.

After the workflow succeeds, run:

```bash
docker buildx imagetools inspect majindageta/gdownloader-docker:1.7.8-1
docker buildx imagetools inspect majindageta/gdownloader-docker:latest
docker pull majindageta/gdownloader-docker:1.7.8-1
docker image inspect majindageta/gdownloader-docker:1.7.8-1 \
  --format '{{.Architecture}} {{index .Config.Labels "org.opencontainers.image.source"}}'
```

Expected: both remote tags resolve to the same digest, the image architecture is `amd64`, and the source label is `https://github.com/majindageta/gdownloader-docker`.
