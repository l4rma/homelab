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
| Checks `pre-commit` and `kubernetes` must pass | Nothing broken or invalid reaches `main`, where Flux applies it (see Checks) |
| No bypass | The rules apply to everyone, including admins |

Approvals are set to 0, because GitHub does not let anyone approve their own pull request
and this is a one-person repository. They go up to 1, with code owner review, once Claude
opens pull requests from its own account ([docs/claude-agent.md](claude-agent.md)).

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
recommends, because a tag can be moved to other code. The repository setting "Require actions
to be pinned to a full-length commit SHA" enforces it: a workflow with an unpinned action does
not run.

| Workflow | What it does |
|---|---|
| `labels.yml` | Syncs labels from `.github/labels.yml` (dry run on pull requests) |
| `pr-labeler.yml` | Adds `area/*` labels to pull requests. Uses `pull_request`, not `pull_request_target`, so code from forks never runs with write access |
| `lint.yml` | The required checks: `pre-commit` and `kubernetes` (below) |
| `scorecard.yml` | [OpenSSF Scorecard](https://scorecard.dev/) grades the repository's security practices (branch protection, pinned actions, token permissions, ...) weekly and after each merge. Results under Security → Code scanning and in the README badge. Some checks cannot pass in a one-person repository (Code-Review, Contributors, Fuzzing) |

## Checks

Two required checks run on every pull request (`lint.yml`). Run them locally before pushing:

| Check | What | Locally |
|---|---|---|
| `pre-commit` | The hooks in [`.pre-commit-config.yaml`](../.pre-commit-config.yaml): whitespace and end of file, YAML/JSON syntax, private keys, yamllint ([`.yamllint.yaml`](../.yamllint.yaml)), markdownlint ([`.markdownlint-cli2.yaml`](../.markdownlint-cli2.yaml)), shellcheck, ruff, actionlint, [zizmor](https://docs.zizmor.sh/) (security audit of the workflows: template injection, permissions, credentials, unpinned actions), gitleaks | `uvx pre-commit run --all-files`, or `uvx pre-commit install` once to run them on every commit |
| `kubernetes` | [flux-schema](https://github.com/fluxcd/flux-schema) builds every kustomize directory under `kubernetes/` and validates each resource against the Kubernetes, Flux and CRD schemas (Gateway API, Envoy Gateway, cert-manager, External Secrets, CloudNativePG ...). Catches wrong fields and types before Flux does | See below |

```sh
docker run --rm -v "$PWD":/repo:ro -w /repo ghcr.io/fluxcd/flux-schema:v0.17.0 \
  validate ./kubernetes --schema-location default --schema-location ecosystem
```

The values inside a `HelmRelease` are not checked against the chart: helm-controller does
that when it installs. flux-schema is in preview; the version is pinned and updated by
Renovate.

Why these tools: pre-commit runs the same hooks on a laptop and in CI, so a pull request
fails for the same reasons it would fail locally, and every hook is pinned to a commit.
Not used: Trivy for configuration scanning. Its GitHub Action had 76 of 77 tags replaced
with malicious code in March 2026
([CVE-2026-33634](https://www.aquasec.com/blog/trivy-supply-chain-attack/)), and policy
checks on the manifests are planned with Kyverno (phase 15), which can run the same
policies in CI and in the cluster.

## Deployment status

The checks above run before a merge. After the merge, Flux posts a commit status on each
commit on `main`, one per Kustomization (`kustomization/flux-system/...`,
`kustomization/infrastructure/...`, `kustomization/apps/...`): green when Flux applied the
commit, red when it failed. So the commit list on GitHub shows what actually runs in the
cluster. It is set up in `kubernetes/infrastructure/flux-notifications/`
([Flux docs](https://fluxcd.io/flux/components/notification/providers/#git-commit-status-updates)).

For `infrastructure` and `apps`, green means the commit was applied **and** everything they
manage is healthy: Deployments and StatefulSets rolled out, HelmReleases installed, PVCs bound,
and custom resources (ExternalSecrets, Certificates, the Postgres cluster) Ready. Both use
`wait: true` with a 10 minute timeout, so a broken rollout turns red with the name of the
object that is not ready. `flux-system` only applies the other two Kustomizations, without
waiting.

The cost: one unhealthy object turns its whole Kustomization red, and while `infrastructure`
is not healthy, `apps` does not apply new commits. Smaller Kustomizations, one per app, would
limit that.

Flux logs in as a GitHub App made for this, `larma-homelab-flux`, instead of a personal token: it
can only write commit statuses on this repository, does not expire, and shows up as its own
bot. To make it again:

1. Settings → Developer settings → GitHub Apps → New GitHub App. Name `larma-homelab-flux`,
   homepage `https://github.com/l4rma/homelab`, Webhook off. Repository permissions:
   Commit statuses "Read and write" (nothing else). "Only on this account".
2. Note the App ID, and generate a private key (a `.pem` file is downloaded).
3. Install App → Only select repositories → `homelab`. The installation ID is the number at
   the end of the URL.
4. Store the key in SSM, then delete the file:
   `aws ssm put-parameter --region eu-west-1 --type SecureString --name /homelab/flux-system/github-app-private-key --value file://<file>.pem`
5. Put the two IDs in `kubernetes/infrastructure/flux-notifications/externalsecret.yaml`.

## Settings (by hand)

| Where | Setting |
|---|---|
| General → Pull Requests | Only "Allow squash merging", default message "Pull request title"; "Always suggest updating pull request branches"; "Allow auto-merge"; "Automatically delete head branches" |
| General → Features | Wiki off, Issues on, Projects on |
| Actions → General | "Require actions to be pinned to a full-length commit SHA" on |
| About (on the repo page) | Description, no topics |
| Advanced Security | Private vulnerability reporting, dependency graph, Dependabot alerts, secret scanning and push protection on. CodeQL default setup. Dependabot security updates off: Renovate reads the alerts and opens those pull requests |
| GitHub Apps | [Mend Renovate](https://github.com/apps/renovate), only for this repository ([dependencies.md](dependencies.md)). `larma-homelab-flux`, own app, commit statuses only ([Deployment status](#deployment-status)) |
