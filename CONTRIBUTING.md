# Contributing

Thank you for improving GDownloader Docker. Keep changes focused on the browser-accessible, fixed `linux/amd64` image described by the repository documentation.

## Before Making Changes

1. Read [AGENTS.md](AGENTS.md) and the specialist document it identifies for your task.
2. Open an ordinary GitHub Issue for a reproducible non-security bug or a proposed change that alters project boundaries.
3. Follow [SECURITY.md](SECURITY.md) instead of opening an issue when a report may describe a vulnerability.
4. Create a dedicated branch and keep unrelated changes out of it.

Changes that add ARM support, authentication, automatic in-container updates, new downloaders, extra persistent mounts, or patches to upstream GDownloader behavior require an explicit design decision before implementation.

## Development Workflow

Update or add the focused test that represents the changed contract before editing the implementation. Run that test to confirm the expected failure, make the smallest corresponding change, and run the focused test again.

Before submitting a change, run:

```bash
bash tests/run.sh
git diff --check
git status --short
```

The complete suite requires Docker and the pinned `linux/amd64` image. On an ARM host, Docker may report expected platform-emulation warnings.

When updating a component, commit the related `versions.env` pins and checksums together with tests, documentation, and any required changes to `LICENSE` or `THIRD_PARTY_NOTICES.md`. Follow [docs/maintenance.md](docs/maintenance.md) for build, verification, deployment, and rollback requirements.

## Sensitive and Local Data

Never commit Docker Hub tokens, API keys, passwords, cookies, downloaded media, runtime logs, or a user's GDownloader configuration. The local `data/` directory is intentionally ignored and must remain untracked. Do not force-add files from it.

Before committing, inspect the staged diff and confirm that examples contain placeholders rather than real credentials, host-specific paths, or personal information.
