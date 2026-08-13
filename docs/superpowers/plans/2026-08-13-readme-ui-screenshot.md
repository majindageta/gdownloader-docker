# README UI Screenshot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add one authentic screenshot of the clean GDownloader interface to the README so it renders on both GitHub and Docker Hub.

**Architecture:** A fresh container created from the published `gdownloader-docker:1.7.8-2` image provides the real noVNC interface. A viewport screenshot is stored as a repository asset, while the README references its absolute raw GitHub URL for cross-site rendering.

**Tech Stack:** Docker, noVNC, PNG, Markdown, Bash documentation tests

## Global Constraints

- Capture the clean, newly started GDownloader UI from `gdownloader-docker:1.7.8-2`.
- Do not include browser chrome, host paths, downloads, user data, annotations, generated content, or retouching.
- Store the screenshot at `docs/images/gdownloader-ui.png`.
- Place the preview immediately after the README introduction and before `## Project Documentation`.
- Reference `https://raw.githubusercontent.com/majindageta/gdownloader-docker/main/docs/images/gdownloader-ui.png` so GitHub and Docker Hub can both render it.

---

### Task 1: Capture and document the clean interface

**Files:**
- Create: `docs/images/gdownloader-ui.png`
- Modify: `README.md`
- Modify: `tests/test-docs.sh`

**Interfaces:**
- Consumes: the published local or remotely pulled Docker image `gdownloader-docker:1.7.8-2` and its noVNC endpoint on container port `5800`.
- Produces: a valid PNG at `docs/images/gdownloader-ui.png` and a README preview using the absolute raw GitHub URL.

- [ ] **Step 1: Write the failing documentation contract**

Append these assertions to `tests/test-docs.sh`:

```bash
ui_screenshot="$repo_dir/docs/images/gdownloader-ui.png"
ui_screenshot_url='https://raw.githubusercontent.com/majindageta/gdownloader-docker/main/docs/images/gdownloader-ui.png'
[[ -s "$ui_screenshot" ]]
[[ $(od -An -tx1 -N8 "$ui_screenshot" | tr -d ' \n') == 89504e470d0a1a0a ]]
grep -Fq '## Interface Preview' "$repo_dir/README.md"
grep -Fq "![GDownloader graphical interface]($ui_screenshot_url)" "$repo_dir/README.md"
```

- [ ] **Step 2: Run the contract and verify the missing asset fails**

Run: `bash tests/test-docs.sh`

Expected: exit code `1` because `docs/images/gdownloader-ui.png` does not exist.

- [ ] **Step 3: Start a clean temporary container**

Create temporary `/config` and `/output` directories, start `gdownloader-docker:1.7.8-2` with an ephemeral localhost port mapped to `5800`, and wait for `/config/logs/current.log` to contain `GDownloader is initialized`. Record the assigned host port and keep a cleanup trap that removes the container and temporary directory.

- [ ] **Step 4: Capture the real noVNC viewport**

Open `http://127.0.0.1:<assigned-port>/` in the in-app browser, wait for the clean GDownloader window, and save a PNG viewport screenshot to `docs/images/gdownloader-ui.png`. Inspect the saved image to confirm that it contains the application UI and no personal data or browser chrome.

- [ ] **Step 5: Add the README preview**

Insert this section after the introductory paragraphs and before `## Project Documentation`:

```markdown
## Interface Preview

![GDownloader graphical interface](https://raw.githubusercontent.com/majindageta/gdownloader-docker/main/docs/images/gdownloader-ui.png)

The original GDownloader Swing interface is available directly in a browser through noVNC.
```

- [ ] **Step 6: Run focused verification**

Run: `bash tests/test-docs.sh && git diff --check`

Expected: exit code `0` with the PNG signature, README heading, and absolute image URL accepted.

- [ ] **Step 7: Run the full repository suite**

Run: `bash tests/run.sh`

Expected: exit code `0`; temporary curl failures during noVNC startup and the intentional read-only `/output` error remain expected smoke-test output.

- [ ] **Step 8: Commit the preview**

```bash
git add README.md docs/images/gdownloader-ui.png tests/test-docs.sh
git commit -m "docs: add GDownloader interface preview"
```

- [ ] **Step 9: Publish and verify rendering**

Push `main`, open the GitHub README and Docker Hub overview, and confirm the PNG renders at normal width on both sites. If Docker Hub does not automatically refresh its manually maintained overview, paste the updated README content into **Repository overview → Edit** without enabling Automated Builds.
