# Releasing

This runbook is for maintainers publishing stable images from GitHub to Docker Hub. Stable images are published only by [the GitHub Actions workflow](../.github/workflows/publish-docker.yml) when a matching GitHub Release is published.

## Configure Docker Hub Authentication

Sign in to Docker Hub, open **Account settings → Personal access tokens**, and generate a dedicated personal access token:

- use the descriptive name `github-actions-gdownloader-docker`;
- grant Read & Write permission;
- copy the token once and store it in a password manager until it has been added to GitHub.

Do not use the Docker Hub account password. Never commit the token, paste it into an issue or chat, place it in a workflow file, or print it in command output.

## Configure GitHub Actions

In the GitHub repository, open **Settings → Secrets and variables → Actions**.

On the **Variables** tab, create the repository variable:

- name: `DOCKERHUB_USERNAME`;
- value: `majindageta`.

On the **Secrets** tab, create the repository secret named `DOCKERHUB_TOKEN` and paste the Docker Hub token as its value.

Return to both tabs and verify that the names appear in their respective lists. GitHub does not reveal the stored secret value; do not attempt to print or recover it. The same name-only check can be performed with `gh variable list` and `gh secret list` after authenticating GitHub CLI for this repository.

## Prepare a Release

Update and verify the project on a dedicated branch according to [the maintenance procedure](maintenance.md). After the verified changes are merged into `main`, derive the required release version from the authoritative manifest:

```bash
source versions.env
release_version="${GDOWNLOADER_VERSION}-${CONTAINER_REVISION}"
printf '%s\n' "$release_version"
```

The GitHub tag must be exactly `v${release_version}`. Run the complete checks before creating it:

```bash
bash tests/run.sh
git diff --check
git status --short
```

Create the tag on the verified `main` commit, push it, and publish a GitHub Release for that tag. Publishing the release starts **Publish Docker image**; an ordinary push to `main` does not publish an image.

## Verify Publication

Wait for the workflow to finish successfully. It validates the release tag, builds and tests the image before authentication, and then pushes the versioned tag and `latest`.

Inspect both public tags:

```bash
docker buildx imagetools inspect "majindageta/gdownloader-docker:${release_version}"
docker buildx imagetools inspect majindageta/gdownloader-docker:latest
```

Both tags must resolve to the same digest, and the image must report `linux/amd64`. Do not move or overwrite an existing stable tag to recover from a failed release. Correct the repository, increment the image revision, and publish a new matching release.

## Replace or Revoke the Credential

If the token is exposed, suspected to be compromised, or no longer used:

1. generate a replacement Docker Hub token with the same dedicated purpose and Read & Write permission;
2. replace the value of the GitHub repository secret `DOCKERHUB_TOKEN` without changing its name;
3. verify the next publication through the GitHub Actions workflow;
4. revoke the old token in Docker Hub.

If immediate containment is required, revoke the affected token first and leave publishing disabled until the replacement secret is configured. Never record token values or sensitive token metadata in this repository.
