# Security policy

This repository is the configuration of a private homelab. Only `main` is supported: it is
what runs.

## Reporting a vulnerability

Please do not open a public issue. Report it privately through GitHub instead:
**Security** tab → **Report a vulnerability**
([how it works](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability)).

Useful to report:

- A secret or credential committed to the repository
- A configuration that exposes a service or data more than intended
- A weakness in the GitHub Actions workflows

Vulnerabilities in the software that runs here (Kubernetes, Flux, the apps) belong with
their upstream projects.

This is a one-person project, so expect an answer within a week.
