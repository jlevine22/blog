---
published: April 18th, 2025
tags:
- markdown
- github
- swift
---

## Rebuilding My Blog in 2025: From Node Servers to Pure GitHub Markdown

<!-- preview -->
Ten years ago I started a blog. As a developer, I *had* to roll my own—Node.js on the backend, Angular on the frontend, and every post sat in a Markdown file with a YAML header that my server parsed. Dropbox handled the sync—simple, cheap, and it just worked.

It served me for almost a decade, but 2025 called for an even leaner setup.
<!-- /preview -->

Markdown is still a good authoring format, but this time I’m letting **GitHub** do the hosting. Zero infrastructure, and anyone can read raw Markdown right in the repo.

### What GitHub Pages *doesn’t* give me

- A dynamic homepage that shows the latest posts with a short teaser
- A way to browse by tags

### The fix: a swift commandline script

Enter [generate_readme.swift](../generate_readme.swift)—about 150 lines of Swift that:

- Scans the `articles/` folder
- Rewrites the main [`README.md`](../README.md) with the five most‑recent posts
- Regenerates an [`Articles.md`](../Articles.md) master index
- Builds a [`Tags.md`](../Tags.md) directory **plus** one file per tag for easy browsing

Commit, Push, and the site is live—no servers, no databases, and no Dropbox daemon eating CPU.

That’s it: a blog you can fork, clone, or read straight from GitHub, powered by a single script and a pile of Markdown.
