---
status: accepted
date: 2026-11-20
---

# A Hugo website built from docs/, published to GitHub Pages

## Context

The documentation is Markdown in `docs/`. It is read on GitHub, and by Claude
from the files. A website with navigation and search makes it easier to read, but a separate
wiki or a second copy of the text would drift away from the repository, and Claude could not
read it. So the website must be built from the same files, without changing how they read
on GitHub: no generator-only syntax, relative links to `.md` files, `README.md` as the index of
a directory, and the title as the first `# heading`.

## Options

Generator:

- **MkDocs with Material for MkDocs**: handles the GitHub-style files without extra work. But
  Material is in maintenance mode, with end of life on 2027-05-05, and MkDocs itself is
  unmaintained, with a 2.0 that removes plugins and that Material cannot run on.
- **Zensical**: the successor from the Material team. Also fits the files as they are, but it is
  pre-1.0, so breaking changes are expected.
- **Hugo** (chosen): stable, one binary, already known. It needs some setup for GitHub-style
  files: a link render hook, the title from the first heading, and `README.md` as an index.

How the docs become Hugo content:

- **`contentDir = '../docs'`**: the simplest, and it works. But Hugo only treats `_index.md` as a
  directory's index, so each `README.md` would become a page of its own (`/decisions/readme/`),
  and `docs/README.md` could not be the home page.
- **Module mounts** (chosen): `docs/` is mounted as content, and single files can be mounted to
  other paths: `docs/README.md` becomes the home page, and each section's `README.md` its
  index page (`docs/decisions/README.md` is `/decisions/`). Mounts can also leave files out
  (the ADR template). The Hugo docs call `contentDir` a legacy setting that must not be
  combined with mounts.

Where it is served:

- **In the cluster** (an image built in CI, rolled out by Flux): good practice, but the docs,
  including the disaster recovery runbook, would be down when the cluster is.
- **GitHub Pages** (chosen): free, needs no secrets, and stays up when the homelab is down. The
  repository is public, so the website shows nothing new.

## Decision

Hugo in `hugo/`, with `docs/` mounted as content, built by
`.github/workflows/docs.yml` on every pull request that touches them and published to GitHub
Pages from `main`.

## Consequences

- Good: one set of Markdown files for GitHub, Claude and the website. A pull request that
  breaks the site fails before it is merged.
- Good: nothing in `docs/` is Hugo-specific. Moving to another generator (Zensical when it
  reaches 1.0, for example) means replacing `hugo/` only.
- Bad: two small templates to maintain. `layouts/_markup/render-link.html` turns relative
  `.md` links into page links, and links to files outside the site into links to GitHub.
  `layouts/_partials/homelab/title.html` gives the title from the first heading, and the theme
  must be told to use it.
- Bad: Hugo cannot see files outside its mounts, so a link to a missing file outside `docs/`
  is not caught at build time.
- Bad: front matter must be valid for Hugo. `date` must be a date, so the ADRs for 0001 to 0006
  no longer say "(written down 2026-11-16)" in it; the decisions README says so instead.

## More information

- [hugo/README.md](../../hugo/README.md): how the site is built and run locally.
- Hugo module mounts: <https://gohugo.io/configuration/module/#mounts>
- Hugo link render hooks: <https://gohugo.io/render-hooks/links/>
- Hugo on GitHub Pages: <https://gohugo.io/host-and-deploy/host-on-github-pages/>
- Material for MkDocs status: <https://squidfunk.github.io/mkdocs-material/blog/2026/02/18/mkdocs-2.0/>
