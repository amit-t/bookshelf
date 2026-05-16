# bookshelf

Personal book corpus + capture CLI.

This repo is the **single source of truth** for the books I've read and what I
learned from each: markdown files with frontmatter under `books/<slug>.md`,
plus a shell-first CLI to capture them from any terminal or agent session. The
corpus is rendered as a public page by
[amittiwari.me](https://amittiwari.me/bookshelf), which consumes this repo as
a git submodule at build time.

Capture a book entry from any terminal or agent session. The skill identifies
the book via Open Library / Google Books, intakes favorite passages, derives
learnings (grounded from your passages + the web, with a hallucination guard
on suggested ones), categorizes into a closed bucket, optionally promotes
selected learnings to the sibling `wisdom` repo, writes a frontmatter markdown
file under `books/`, and commits.

## Quickstart

```bash
git clone <this-repo> ~/Projects/AmitTiwari/bookshelf
cd ~/Projects/AmitTiwari/bookshelf

# 1. CLI on PATH
./install.sh
# Follow the printed instructions to add BOOKSHELF_REPO + PATH to ~/.zshrc

# 2. bookshelf-capture skill into this project
npx skills@latest add amit-t/skills --skill bookshelf-capture

bookshelf "Atomic Habits" --author "James Clear"
```

The skill is published in the [at-skills catalog](https://github.com/amit-t/skills/tree/main/bookshelf-capture).
Re-run the `npx` command to upgrade.

## Subcommands

See [`docs/USAGE.md`](./docs/USAGE.md).

## Install

See [`docs/INSTALL.md`](./docs/INSTALL.md).

## Architecture

See [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md).

## License

Dual: MIT for code, CC BY 4.0 for the corpus under `books/`. See
[`LICENSE`](./LICENSE).
