# Complete English Documentation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert every tracked repository document and contributor-facing documentation assertion to clear technical English without changing project behavior.

**Architecture:** Translate the current operator and contributor documentation together with its executable documentation contract, then translate the historical specifications and plans as a separate reviewable unit. Preserve all technical values and verify both language coverage and the existing repository test suite.

**Tech Stack:** Markdown, Bash, ripgrep, Docker Compose, Git

## Global Constraints

- Translate all tracked Markdown documentation that contains Italian prose.
- Translate contributor-facing prose in tracked non-Markdown files when found.
- Keep commands, paths, filenames, environment variables, image tags, versions, checksums, source identifiers, and application names exact.
- Preserve the exclusive `linux/amd64` target and all existing Docker runtime contracts.
- Do not modify runtime scripts, the Dockerfile, Compose behavior, configuration defaults, versions, dependencies, or local runtime data.
- Keep `LICENSE` unchanged and avoid cosmetic changes to text that is already English.
- Exclude the untracked `data/` directory from every commit.
- Preserve warnings about trusted local networks, missing default authentication, backups, rollback, and unsupported features.

---

## Planned File Map

- `README.md`: English operator entry point and deployment guide.
- `AGENTS.md`: English contributor router, project constraints, and workflow.
- `docs/architecture.md`: English architecture reference.
- `docs/glossary.md`: English canonical terminology.
- `docs/maintenance.md`: English component update, deployment, and rollback procedure.
- `docs/verification.md`: English end-to-end verification record.
- `tests/test-docs.sh`: executable assertions updated to the canonical English wording.
- `docs/superpowers/specs/2026-08-11-agent-documentation-design.md`: translated historical design record.
- `docs/superpowers/specs/2026-08-11-gdownloader-docker-design.md`: translated historical design record.
- `docs/superpowers/plans/2026-08-11-agent-documentation-implementation.md`: translated historical implementation plan, including embedded document excerpts.
- `docs/superpowers/plans/2026-08-11-gdownloader-docker-implementation.md`: translated historical implementation plan, including embedded README excerpts.

The already-English design and this plan remain unchanged during implementation:

- `docs/superpowers/specs/2026-08-12-english-documentation-design.md`;
- `docs/superpowers/plans/2026-08-12-english-documentation-implementation.md`.

### Task 1: Translate Current Documentation and Its Executable Contract

**Files:**

- Modify: `tests/test-docs.sh`
- Modify: `README.md`
- Modify: `AGENTS.md`
- Modify: `docs/architecture.md`
- Modify: `docs/glossary.md`
- Modify: `docs/maintenance.md`
- Modify: `docs/verification.md`

**Interfaces:**

- Consumes: the runtime and documentation contracts defined by the current Italian documents and `tests/test-docs.sh`.
- Produces: canonical English operator and contributor documentation whose wording is enforced by `tests/test-docs.sh`.

- [ ] **Step 1: Change documentation assertions to the canonical English wording**

Update the exact phrases and headings asserted by `tests/test-docs.sh` before translating the documents:

```text
solo nella rete locale       -> trusted local network
aggiornamento manuale        -> manual update
Pipeline di build            -> Build Pipeline
Sequenza di avvio            -> Startup Sequence
Persistenza                  -> Persistence
Rete e sicurezza             -> Networking and Security
Confini intenzionali         -> Intentional Boundaries
Immagine fixed               -> Fixed Image
Base image jlesage           -> jlesage Base Image
Desktop virtuale             -> Virtual Desktop
Stato persistente            -> Persistent State
Eseguibile di sistema        -> System Executable
Checksum SHA-256             -> SHA-256 Checksum
```

Keep the wording of technical glossary headings that is already canonical English, while normalizing heading capitalization: `Upstream`, `Portable Mode`, `noVNC`, `Bootstrap`, `Config Seed`, `Bind Mount`, `Volume`, `/config`, `/output`, `Pin`, `Image Revision`, `Health Check`, and `Smoke Test`.

The architecture assertion loop must become:

```bash
for heading in 'Build Pipeline' 'Startup Sequence' 'Persistence' 'Networking and Security' 'Intentional Boundaries'; do
  grep -F "## $heading" "$repo_dir/docs/architecture.md"
done
```

The translated glossary assertion list must contain:

```bash
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
  '## Smoke Test'
```

- [ ] **Step 2: Run the documentation test and confirm the expected failure**

Run:

```bash
bash tests/test-docs.sh
```

Expected: FAIL because the documents still contain the former Italian phrases or headings, such as `solo nella rete locale` or `## Pipeline di build`.

- [ ] **Step 3: Translate `AGENTS.md` and preserve its routing contract**

Use these English headings:

```text
# Agent Context
## Purpose
## Reading by Task
## Non-Negotiable Constraints
## Authoritative Sources
## Workflow
## Essential Commands
```

Translate the table, prose, and workflow instructions. Preserve every referenced path, command, and constraint. The file must still route build/runtime/GUI work to `docs/architecture.md`, terminology work to `docs/glossary.md`, component updates to `docs/maintenance.md`, image evidence to `docs/verification.md`, and installation work to `README.md`.

- [ ] **Step 4: Translate `README.md` as the operator-facing entry point**

Use these English headings:

```text
# GDownloader Docker
## Project Documentation
## Runtime Requirements
## Build
## Running with Docker
## Docker Compose
## Portainer Stack
## Optional Variables
## Persistence and Backup
## Updating
## Security
## Troubleshooting
## Included Component Sources
```

Translate every paragraph, list item, table label, warning, and troubleshooting label. Preserve all shell and YAML blocks byte-for-byte unless an English comment or explanatory placeholder occurs inside them. Keep current tags, ports, mounts, URLs, variable names, and component versions exact.

- [ ] **Step 5: Translate `docs/architecture.md` without changing system boundaries**

Use this heading map:

```text
# Architecture
## Purpose and Scope
## Build Pipeline
## Image Contents
## Startup Sequence
## Application State
## Persistence
## GUI and Networking
## Permissions and Identity
## Health Check
## Networking and Security
## Intentional Boundaries
## Implementation Map
```

Translate all prose while preserving the documented HTTP/noVNC/TigerVNC/Openbox/Swing flow, persistent-state paths, permission model, health-check limitation, and unsupported-feature boundaries.

- [ ] **Step 6: Translate `docs/glossary.md` using canonical English terms**

Use this complete heading sequence:

```text
# Glossary
## Upstream
## Fixed Image
## Portable Mode
## jlesage Base Image
## noVNC
## Virtual Desktop
## Bootstrap
## Config Seed
## Persistent State
## Bind Mount
## Volume
## `/config`
## `/output`
## System Executable
## Pin
## SHA-256 Checksum
## Image Revision
## Health Check
## Smoke Test
```

Because Markdown headings are case-sensitive in the test, align `tests/test-docs.sh` with this title case. Each definition must retain its repository-specific distinctions, especially bind mount versus volume, noVNC versus a native web UI, health check versus functional download, and pin versus image revision.

- [ ] **Step 7: Translate `docs/maintenance.md` as an executable procedure**

Use these headings:

```text
# Maintenance and Updates
## Scope and Prerequisites
## Approved Sources
## Preparing New Pins
### GDownloader
### yt-dlp
### Deno
### FFmpeg and ffprobe
### jlesage Base Image
## Image Revision
## Licenses and Notices
## Build
## Required Verification
## Deployment
## Rollback
## Completing the Update
```

Translate prose and numbered procedures without modifying download URLs, asset names, shell commands, environment variables, pin rules, checksum workflow, backup requirements, or rollback semantics.

- [ ] **Step 8: Translate `docs/verification.md` as an evidence record**

Use these headings:

```text
# End-to-End Verification
## Environment
## Observed Components
## GUI Verification
## Authorized Download
## Recreation and Persistence
## Verified Commands
```

Preserve dates, versions, paths, measurements, observed outcomes, command blocks, and qualifications. Do not turn historical observations into broader guarantees.

- [ ] **Step 9: Run the focused documentation test**

Confirm that `tests/test-docs.sh` expects the exact final headings `Build Pipeline`, `Startup Sequence`, `Networking and Security`, `Intentional Boundaries`, `Fixed Image`, `jlesage Base Image`, `Virtual Desktop`, `Persistent State`, `System Executable`, and `SHA-256 Checksum`.

Run:

```bash
bash tests/test-docs.sh
```

Expected: PASS with all Compose, cross-link, constraint, glossary, maintenance, and incomplete-marker checks succeeding.

- [ ] **Step 10: Review the current documentation for residual Italian prose**

Run this targeted review scan:

```bash
rg -n -i --glob '*.md' '\b(aggiornamento|architettura|avvio|cartella|contenitore|documentazione|immagine|manutenzione|persistenza|progetto|rete|scaricare|verifica|vincoli)\b' \
  AGENTS.md README.md docs/architecture.md docs/glossary.md docs/maintenance.md docs/verification.md
```

Expected: no Italian prose. Inspect any match manually because shared technical terms or quoted source material may be legitimate.

- [ ] **Step 11: Commit the current English documentation**

```bash
git add AGENTS.md README.md docs/architecture.md docs/glossary.md docs/maintenance.md docs/verification.md tests/test-docs.sh
git diff --cached --check
git commit -m "docs: translate operational documentation to English"
```

Expected: one commit containing only the seven current documentation/test files; `data/` remains untracked and unstaged.

### Task 2: Translate Historical Specifications and Plans

**Files:**

- Modify: `docs/superpowers/specs/2026-08-11-agent-documentation-design.md`
- Modify: `docs/superpowers/specs/2026-08-11-gdownloader-docker-design.md`
- Modify: `docs/superpowers/plans/2026-08-11-agent-documentation-implementation.md`
- Modify: `docs/superpowers/plans/2026-08-11-gdownloader-docker-implementation.md`

**Interfaces:**

- Consumes: the exact historical decisions, requirements, commands, snippets, and implementation status recorded in the four Italian documents.
- Produces: faithful English historical records that remain consistent with the canonical current documentation from Task 1.

- [ ] **Step 1: Translate the agent-documentation design record**

Translate all prose in `docs/superpowers/specs/2026-08-11-agent-documentation-design.md`. Use this heading structure:

```text
# Project Documentation for Agents: Design Specification
## 1. Objective
## 2. Principles
## 3. Documentation Structure
### 3.1 `AGENTS.md`
### 3.2 `docs/architecture.md`
### 3.3 `docs/glossary.md`
### 3.4 `docs/maintenance.md`
### 3.5 `README.md`
## 4. Authoritative Sources
## 5. Constraints to Preserve
## 6. Agent Usage Workflow
## 7. Documentation Error Handling
## 8. Verification Strategy
## 9. Completion Criteria
```

Preserve the original design choices and historical scope. Translate example wording inside code blocks when that wording represents documentation output.

- [ ] **Step 2: Translate the original Docker design record**

Translate all prose in `docs/superpowers/specs/2026-08-11-gdownloader-docker-design.md`. Use this heading structure:

```text
# GDownloader Docker: Design Specification
## 1. Objective
## 2. Scope
## 3. Architectural Decision
## 4. Image Build
## 5. Runtime Layout
## 6. Initialization and Startup
## 7. Updates and Immutability
## 8. Docker Contract
## 9. Runtime Parameters
## 10. Security and Networking
## 11. Error Handling
## 12. Versioning
## 13. Planned Repository Structure
## 14. Verification Strategy
## 15. Completion Criteria
```

Do not modernize or amend historical decisions during translation. Keep all filenames, paths, tags, variables, examples, and numeric values exact.

- [ ] **Step 3: Translate the agent-documentation implementation plan**

Translate all remaining Italian prose in `docs/superpowers/plans/2026-08-11-agent-documentation-implementation.md`, including task names, checkbox steps, expected results, embedded sample documents, tables, and comments. Use these task titles:

```text
### Task 1: Agent Router and Architecture
### Task 2: Canonical Glossary
### Task 3: Maintenance Procedure and README Index
### Task 4: Final Documentation Audit
```

Keep the plan's existing English header fields and exact commands. Embedded examples must use the same canonical English headings and terminology established in Task 1 of this plan.

- [ ] **Step 4: Translate the original Docker implementation plan**

Translate all remaining Italian prose in `docs/superpowers/plans/2026-08-11-gdownloader-docker-implementation.md`, including descriptions, constraints, checkbox steps, expected results, comments, diagnostics, and embedded README content. Its existing English task headings may remain unchanged.

Preserve executable shell, Dockerfile, JSON, and YAML content unless the text is a human-facing Italian message or comment. Do not change historical values or silently correct historical implementation instructions.

- [ ] **Step 5: Scan every tracked documentation file for residual Italian prose**

Run:

```bash
git ls-files '*.md' | xargs rg -n -i '\b(aggiornamento|architettura|avvio|cartella|contenitore|documentazione|immagine|manutenzione|persistenza|progetto|rete|scaricare|verifica|vincoli)\b'
```

Expected: no residual Italian prose. Review matches manually before changing technical names, URLs, quotations, or words that are valid in English.

Also inspect the complete documentation diff:

```bash
git diff --word-diff=color -- docs/superpowers/specs docs/superpowers/plans
```

Confirm that commands, paths, versions, checksums, and code behavior have not changed.

- [ ] **Step 6: Run focused and full verification**

Run:

```bash
bash tests/test-docs.sh
bash tests/run.sh
git diff --check
```

Expected: all commands exit with status 0. Docker-dependent checks must retain their documented skip behavior when no local image is available; any actual failure must be investigated rather than described as a pass.

- [ ] **Step 7: Commit the translated historical records**

```bash
git add \
  docs/superpowers/specs/2026-08-11-agent-documentation-design.md \
  docs/superpowers/specs/2026-08-11-gdownloader-docker-design.md \
  docs/superpowers/plans/2026-08-11-agent-documentation-implementation.md \
  docs/superpowers/plans/2026-08-11-gdownloader-docker-implementation.md
git diff --cached --check
git commit -m "docs: translate historical project records to English"
```

Expected: one commit containing only the four historical documents.

- [ ] **Step 8: Perform the final repository review**

Run:

```bash
git status --short
git log -3 --oneline --decorate
```

Expected: the English-documentation design commit and the two translation commits are visible. `data/` remains the only unrelated untracked path, and no runtime or configuration file is modified.
