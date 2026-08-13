# Security Policy

## Supported Version

Only the current stable release published on GitHub and Docker Hub is supported with security fixes. Before reporting a problem, reproduce it with the current versioned image rather than an older tag or a locally modified build.

## Security Boundary

The browser interface is unauthenticated by default and is intended only for a trusted local network. Do not expose port `5800` directly to the Internet. Use a VPN or an authenticated reverse proxy protected with TLS for remote access.

This repository is responsible for the Docker packaging, image build, startup scripts, persistence behavior, and publication workflow. Vulnerabilities in the upstream GDownloader application should be reported to the [GDownloader project](https://github.com/hstr0100/GDownloader) unless the Docker packaging introduces or amplifies the issue.

## Reporting a Vulnerability

Use [GitHub Private vulnerability reporting](https://github.com/majindageta/gdownloader-docker/security/advisories/new) for suspected vulnerabilities in this repository. Include the affected image tag, a concise impact description, reproduction steps, and any relevant logs with sensitive values removed.

Do not open a public issue for an undisclosed vulnerability. Do not publish credentials, cookies, personal data, sensitive logs, or working exploits in an issue, discussion, or pull request. Ordinary bugs that do not have a security impact may be reported through GitHub Issues.
