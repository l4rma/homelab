# Docs website (Hugo)

The website for the docs, built with [Hugo](https://gohugo.io/). It has no content of its
own: [`docs/`](../docs/README.md) is mounted as content, so the
same Markdown files are read on GitHub, by Claude and on the website. Why Hugo, and why
mounts instead of `contentDir`: [ADR 0015](../docs/decisions/0015-hugo-for-the-docs-website.md).

## How the files map to pages

Set in [`hugo.toml`](hugo.toml) under `module.mounts`:

| File | Page |
|---|---|
| `docs/README.md` | The home page |
| `docs/<section>/README.md` | `/<section>/`, the section's index page |
| `docs/<section>/<name>.md` | `/<section>/<name>/` |
| `docs/decisions/template.md` | Not on the site, links to it go to GitHub |

The sections' order in the menu is set with `cascade` in `hugo.toml`. Pages within a
section are in file name order.

## Writing docs

Write for GitHub, as before. The website follows these rules, so keep to them:

- Start each file with one `# Title`. It is the page title in menus and the browser tab
  ([`layouts/_partials/homelab/title.html`](layouts/_partials/homelab/title.html)).
- Link to other files with relative paths, the way GitHub expects: `../storage.md`,
  `decisions/0011-....md#options`. [`layouts/_markup/render-link.html`](layouts/_markup/render-link.html)
  turns links to docs into links to their pages, and links to anything else in the
  repository (manifests, workflows, other READMEs) into links to the file on GitHub.
- Front matter is optional, but what is there must be valid for Hugo: `date` must be a date
  (`YYYY-MM-DD`).
- A new section (a directory in `docs/`) needs a `README.md`, a mount for it in
  `hugo.toml` to make it the section's index page, and a `cascade` entry for its place in
  the menu.

## Run it locally

Install the Hugo version in [`.github/workflows/docs.yml`](../.github/workflows/docs.yml)
(`HUGO_VERSION`, the extended edition) and Go (for the theme, a Hugo module), then:

```sh
hugo server --source hugo
```

The site is at <http://localhost:1313/> and reloads when a file in `docs/` changes.

## Build and publish

[`docs.yml`](../.github/workflows/docs.yml) builds the site on every pull request that
changes `docs/` or `hugo/`, and publishes it to GitHub Pages from `main`.
Renovate updates `HUGO_VERSION` and the actions ([docs/operations/dependencies.md](../docs/operations/dependencies.md)).
