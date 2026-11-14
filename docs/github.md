# GitHub repository

How the repository itself is set up. Settings that cannot live in Git are listed here, so
they can be checked and set again by hand.

## Ruleset on `main`

Defined in [`.github/rulesets/main.json`](../.github/rulesets/main.json). GitHub does not
read the file by itself. Apply a change with:

```sh
gh api -X PUT repos/l4rma/homelab/rulesets/<id> --input .github/rulesets/main.json
```

(`gh api repos/l4rma/homelab/rulesets` lists the id. The first time, use
`gh api -X POST repos/l4rma/homelab/rulesets --input .github/rulesets/main.json`, or import
the file under Settings → Rules → Rulesets.)

| Rule | Why |
|---|---|
| No deletion, no force push | `main` is what Flux runs. Its history must not change |
| Changes only through a pull request | Every change is reviewed and recorded, also when made by the owner |
| Squash merge only, linear history | One commit per pull request, named after the PR title. A rollback is one `git revert` |
| Conversations resolved before merge | Review comments are answered, not forgotten |
| No bypass | The rules apply to everyone, including admins |

Approvals are set to 0, because GitHub does not let anyone approve their own pull request
and this is a one-person repository. They go up to 1, with code owner review, once Claude
opens pull requests from its own account ([docs/claude-agent.md](claude-agent.md)).
Required status checks are added together with the checks themselves.

Docs: [About rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets),
[available rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets).

## Code owners

[`.github/CODEOWNERS`](../.github/CODEOWNERS): the owner is asked to review every pull
request.

## Issues and pull requests

- **Issue forms** in [`.github/ISSUE_TEMPLATE/`](../.github/ISSUE_TEMPLATE/): bug, feature or
  change, maintenance, and incident (a blameless write-up after an outage). Blank issues are
  off. Security problems go to private reporting instead ([SECURITY.md](../SECURITY.md)).
- **Pull request template** ([`.github/pull_request_template.md`](../.github/pull_request_template.md)):
  what and why, how it was verified, manual steps, rollback.
- **Labels** are defined in [`.github/labels.yml`](../.github/labels.yml) and synced by a
  workflow after each merge. Labels not in the file are deleted. `type/*` says what kind of
  work, `area/*` which part of the homelab, `manual-step` that something is done by hand
  outside Git. Pull requests get `area/*` labels from the paths they change
  ([`.github/labeler.yml`](../.github/labeler.yml)).
- **Epics:** each phase or larger goal is an issue labelled `type/epic`, with the steps as
  [sub-issues](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/adding-sub-issues).

## Project board

[Homelab](https://github.com/users/l4rma/projects) (GitHub Projects), made by hand:

| Field | Values |
|---|---|
| Status | Backlog, Ready, In progress, In review, Done |
| Priority | P0 (now, something is broken), P1 (next), P2 (later), P3 (someday) |
| Size | S (an hour), M (an evening), L (a weekend), XL (split it) |

Views: **Board** (by Status), **Epics** (table grouped by parent issue), **Roadmap** (by
Priority). Built-in workflows: new issues and pull requests from this repository are added
as Backlog, and closed or merged items move to Done.

## Workflows

All in [`.github/workflows/`](../.github/workflows/). Every workflow starts with
`permissions: {}` and each job asks only for what it needs. Actions are pinned to a full
commit SHA with the version in a comment, as GitHub's
[secure use reference](https://docs.github.com/en/actions/reference/security/secure-use)
recommends, because a tag can be moved to other code.

| Workflow | What it does |
|---|---|
| `labels.yml` | Syncs labels from `.github/labels.yml` (dry run on pull requests) |
| `pr-labeler.yml` | Adds `area/*` labels to pull requests. Uses `pull_request`, not `pull_request_target`, so code from forks never runs with write access |

## Settings (by hand)

| Where | Setting |
|---|---|
| General → Pull Requests | Only "Allow squash merging", default message "Pull request title and description"; "Always suggest updating pull request branches"; "Allow auto-merge"; "Automatically delete head branches" |
| General → Features | Wiki off, Issues on, Projects on |
| About (on the repo page) | Description and topics |
| Advanced Security | Private vulnerability reporting, dependency graph, Dependabot alerts, secret scanning and push protection on. CodeQL default setup. Dependabot security updates off: Renovate will open those pull requests |
