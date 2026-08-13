# README UI Screenshot Design

**Date:** August 13, 2026

## Goal

Show prospective users what GDownloader looks like before they deploy the container. The README will contain one authentic screenshot of the clean, newly started graphical interface exposed through noVNC.

## Capture

- Run the published `gdownloader-docker:1.7.8-2` image with fresh temporary `/config` and `/output` bind mounts.
- Open the noVNC web interface and wait until GDownloader is fully initialized.
- Capture the application viewport without browser chrome, host paths, downloads, user data, or added annotations.
- Preserve the application's natural appearance; do not generate, retouch, or composite the UI.

## Repository Placement

Store the PNG at `docs/images/gdownloader-ui.png`. Use PNG to keep Swing text and controls sharp without animation overhead.

## README Placement

Add a short `## Interface Preview` section immediately after the introductory paragraphs and before `## Project Documentation`. Include descriptive alt text and a concise caption explaining that the original Swing interface is accessed through noVNC.

Reference the image using the absolute raw GitHub URL:

`https://raw.githubusercontent.com/majindageta/gdownloader-docker/main/docs/images/gdownloader-ui.png`

The absolute URL ensures the image renders both in the GitHub README and in the manually maintained Docker Hub repository overview.

## Verification

- Confirm the screenshot contains the clean GDownloader UI and no personal data.
- Confirm the PNG is tracked in Git and renders from the README.
- Run the documentation tests and `git diff --check`.
