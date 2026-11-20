---
status: accepted
date: 2026-11-16
---

# No bot account or auto-approval for Claude's pull requests

## Context

Claude Code writes most changes in this repository, on a branch. I read them, commit them
under my own name (with a `Co-Authored-By` line for Claude), open the pull request and merge
it. The ruleset on `main` requires a pull request and the checks, but 0 approvals, because
GitHub does not let anyone approve their own pull request. So OpenSSF Scorecard gives a low
Code-Review score, and the rule "a change needs an approval" cannot be turned on.

## Options

- **A user account for Claude** (a machine user): Claude pushes branches and opens pull
  requests, I approve them, and the ruleset can require 1 approval. But with squash merges
  the commit on `main` is credited to the pull request's author, so the account would soon
  have most of the commits in a repository that shows my work. And I am there for every
  change anyway, so the approval would be me clicking "approve" on something I just watched
  being written.
- **A GitHub App for Claude**: the same, with a narrower identity and no extra user account.
  Same drawbacks.
- **A bot that approves every pull request**: raises the Code-Review score, but nothing is
  reviewed, so the score would be false. The required approval would also pass for any pull
  request, including one opened with a misused token.
- **Keep the current flow** (chosen): Claude writes, I review, commit and merge.

## Decision

Chosen: keep the current flow. This is how one developer usually works with an AI assistant:
the person who commits is responsible for the change. A separate identity for Claude makes
sense when it works without me at the keyboard (for example on a schedule in the cloud), and
then it should be a GitHub App, like [0009](0009-github-app-for-flux.md).

## Consequences

- Good: the history shows who is responsible for each change, and Claude is credited in each
  commit.
- Good: Claude keeps read-only access to GitHub. It cannot push or open pull requests.
- Bad: no recorded review on pull requests, and Scorecard's Code-Review check stays low. Every
  change still goes through a pull request with the required checks.
- Bad: committing, pushing and opening the pull request are done by hand.

## More information

[docs/development/github.md](../development/github.md#ruleset-on-main), [docs/development/claude-agent.md](../development/claude-agent.md),
[Scorecard Code-Review check](https://github.com/ossf/scorecard/blob/main/docs/checks.md#code-review).
Issue #70 was closed as not planned.
