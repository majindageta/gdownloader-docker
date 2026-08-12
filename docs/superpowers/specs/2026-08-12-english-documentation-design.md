# Complete English Documentation Design

## 1. Objective

Convert all repository documentation from Italian to clear technical English so international users, maintainers, and coding agents can understand and contribute to the project without relying on translation tools.

This change is documentation-only. It must not alter the container runtime, image contents, dependency versions, configuration defaults, supported platform, network behavior, or persistence model.

## 2. Scope

The translation covers every tracked Markdown document that contains Italian prose:

- `README.md`;
- `AGENTS.md`;
- `docs/architecture.md`;
- `docs/glossary.md`;
- `docs/maintenance.md`;
- `docs/verification.md`;
- all historical specifications under `docs/superpowers/specs/`;
- all historical implementation plans under `docs/superpowers/plans/`.

Documentation assertions in `tests/test-docs.sh` must be updated whenever they depend on translated headings, terms, or sentences. Other tracked text files must be scanned for Italian user-facing or contributor-facing prose and translated if found.

`LICENSE` remains unchanged because it contains the authoritative upstream license text. `THIRD_PARTY_NOTICES.md` and text that is already English require no cosmetic rewrite. The untracked runtime directory `data/` is local state and is excluded from the change.

## 3. Language and Terminology

All explanatory prose, headings, table labels, link descriptions, test diagnostics, and contributor instructions must use natural technical English.

Commands, paths, filenames, environment variables, image tags, version values, checksums, source identifiers, and application names must remain exact. Established technical terms such as noVNC, Swing, bind mount, health check, smoke test, fixed image, bootstrap, pin, and image revision must be used consistently across documents.

Translations must preserve meaning rather than mirror Italian sentence structure. Existing warnings and limitations must retain their strength, especially statements concerning trusted local networks, the lack of default authentication, backups, rollback, and unsupported features.

## 4. Preserved Project Contracts

The English documentation must preserve these existing facts:

- the image supports only `linux/amd64`;
- the original Swing GUI is exposed through noVNC on internal port `5800`;
- VNC port `5900` is not published by default;
- the image uses a fixed, rebuild-and-recreate update model;
- GDownloader, yt-dlp, Deno, FFmpeg, and ffprobe are included;
- gallery-dl and spotDL are not installed and remain disabled;
- only `/config` and `/output` are persistent mounts;
- an existing valid `/config/config.json` is not overwritten;
- automatic updates remain disabled;
- the unauthenticated interface is intended only for a trusted local network;
- ARM support, integrated authentication, new downloaders, extra volumes, automatic in-container updates, and upstream Java patches remain outside the approved scope.

## 5. Document Responsibilities

`README.md` remains the operator-facing entry point for building, running, configuring, backing up, updating, securing, and troubleshooting the image.

`AGENTS.md` remains the contributor and coding-agent router. It must direct readers to the appropriate operational document and retain the authoritative constraints and verification workflow.

The operational documents retain separate responsibilities:

- `docs/architecture.md` explains system composition, build flow, startup, persistence, networking, permissions, and intentional boundaries;
- `docs/glossary.md` defines the repository's canonical terminology;
- `docs/maintenance.md` describes safe component updates, builds, deployment, and rollback;
- `docs/verification.md` records evidence and limitations of the verified image.

Historical specifications and plans remain historical records. Their requirements, decisions, commands, code excerpts, and status must not be reinterpreted during translation.

## 6. Automated Documentation Contract

`tests/test-docs.sh` must assert the translated English headings and critical phrases while retaining all existing behavioral coverage. The test must continue to validate:

- Compose configuration and exposed ports;
- persistent mount documentation;
- local-network security guidance;
- manual update guidance;
- third-party notices;
- document presence and cross-links;
- architecture headings and glossary entries;
- maintenance sources, components, commands, and rollback guidance;
- absence of incomplete markers in operational documentation.

Translation must not weaken a test merely to make it pass. Assertions should follow the final canonical English wording.

## 7. Verification

The completed change must pass, in order:

1. a repository-wide scan of tracked text for remaining Italian prose;
2. `bash tests/test-docs.sh`;
3. `bash tests/run.sh`;
4. `git diff --check`;
5. a final review of `git status --short` confirming that only intended tracked documentation and test changes are part of the translation.

The language scan is a review aid rather than proof by itself: technical words shared by Italian and English may produce false positives, and short Italian phrases may require manual inspection.

## 8. Acceptance Criteria

The work is complete when:

- all tracked repository documentation is understandable without Italian-language knowledge;
- no known Italian explanatory prose remains in tracked documentation or contributor-facing test messages;
- technical values, commands, links, and project contracts remain accurate;
- documentation links and automated assertions remain valid;
- the complete test suite passes;
- runtime code, image configuration, versions, and local runtime data are unchanged.
