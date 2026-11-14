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

## Settings (by hand)

| Where | Setting |
|---|---|
| General → Pull Requests | Only "Allow squash merging", default message "Pull request title and description"; "Always suggest updating pull request branches"; "Allow auto-merge"; "Automatically delete head branches" |
| General → Features | Wiki off, Issues on, Projects on |
| About (on the repo page) | Description and topics |
| Advanced Security | Private vulnerability reporting, dependency graph, Dependabot alerts, secret scanning and push protection on. CodeQL default setup. Dependabot security updates off: Renovate will open those pull requests |
