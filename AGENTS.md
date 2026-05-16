# AGENTS.md

This repo is a personal book corpus. Any agent (Claude Code, Codex, Devin)
entering this repo should follow these rules.

## When asked to log a book

Load and follow the `bookshelf-capture` skill exactly.

The skill is installed per-project from the at-skills catalog. Engine-specific
locations after install:

- Claude Code: `.claude/skills/bookshelf-capture/SKILL.md` (project-level)
- Devin / Windsurf: `.cognition/skills/bookshelf-capture/SKILL.md`
- Cursor: `.cursor/skills/bookshelf-capture/SKILL.md`
- Codex: skill content is concatenated into this `AGENTS.md` by the installer

If you cannot find the skill in any of those locations, the user has not run
the installer yet. From the repo root:

```bash
npx skills@latest add amit-t/skills --skill bookshelf-capture
```

Triggers inside an agent session:

- Claude Code: `/bookshelf-capture` (or just describe the task — the skill
  description triggers auto-invoke)
- Devin: `/bookshelf-capture`
- Codex: `$bookshelf-capture`

The terminal CLI shortcut is `bookshelf "<title>"` — that command launches an
agent session in this repo with the title pre-fed; the skill takes over.

## Repository conventions

- Books live in `books/<slug>.md` with frontmatter per `docs/ARCHITECTURE.md`.
- Categories are closed; source of truth is `books/_categories.yml`.
- Shelves are open, but the skill suggests existing ones from
  `books/_shelves.yml` to prevent typo-splits.
- One commit per book entry (or per re-read). Format:
  `book: <category> — <title> by <author-last>`.
- Wisdom promotion commits land in `~/Projects/AmitTiwari/wisdom` (separate
  repo). The book commit lands last, with `wisdom_ids` already populated.

## Tests

Run `zsh tests/run.zsh` before declaring work complete.

## What NOT to do

- Do not edit `books/_categories.yml` to add new buckets without explicit user
  confirmation (the skill handles this interactively).
- Do not batch-rewrite frontmatter across many book files unless asked.
- Do not use `git add -A`. Always stage specific files.
- Do not skip pre-commit hooks (no `--no-verify`).

## Pushing changes

Direct push to `main` is policy-blocked. When `git push origin main` is denied
with a direct-push-to-main reason, do NOT surface that as a dead end. Fall
back automatically:

1. Create a topic branch at the current HEAD (`book/<slug-prefix>` for book
   commits, `fix/<slug>` / `feat/<slug>` otherwise).
2. Reset local `main` to `origin/main` so it stays clean.
3. Push the topic branch.
4. Open a PR to `main` with `gh pr create`.

Report the PR URL back to the user. This applies to all agents, not just the
capture flow.

## amittiwari.me integration

The amittiwari.me Next.js site consumes this repo as a git submodule at
`external/bookshelf` and bridges the rich schema to its existing `Book` type.
Bookshelf is the single source of truth; the markdown frontmatter is the wire
format both sides consume.

- If you change the frontmatter shape, update the matching bridge in
  `amittiwari-me/src/lib/books.ts` as well.
- If you rename `books/_categories.yml` or restructure `books/<slug>.md`,
  update the data layer there too.

### Auto-redeploy on push

`.github/workflows/trigger-amittiwari-me.yml` calls the DigitalOcean API on
every push to main and asks App Platform to redeploy the amittiwari.me app,
so a new `bookshelf "..."` capture goes live without manual steps.

One-time setup (only when the token rotates or the app is re-created):
1. Create a DO Personal Access Token at
   `https://cloud.digitalocean.com/account/api/tokens` with `apps:read` +
   `apps:write` scopes.
2. Grab the App ID for amittiwari.me from the DO console.
3. This repo → Settings → Secrets and variables → Actions → add both:
   - `DO_API_TOKEN` = token from step 1
   - `DO_APP_ID` = UUID from step 2

Missing either secret turns the workflow into a no-op with a warning, so
pushes are never blocked.
