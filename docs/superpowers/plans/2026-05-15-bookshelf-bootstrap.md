# Bookshelf Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the `bookshelf` repo as the single-source corpus + CLI + agent skill for capturing books and their learnings, mirroring the wisdom repo topology, and wire it into amittiwari.me via a submodule bridge.

**Architecture:** Markdown-per-book under `books/<slug>.md` with rich YAML frontmatter and structured body sections (`## Summary`, `## Top Learnings`, `## Favorite Passages`, `## Notes`, `## Re-read <year>`). A zsh CLI (`bin/bookshelf` dispatching to `lib/cmd_*.zsh`) launches an agent session that runs the `bookshelf-capture` skill — a 14-step flow that identifies the book via Open Library/Google Books, intakes passages, derives learnings (grounded from passages + web; suggests more from priors with a hallucination guard, cap 5), categorizes against a closed taxonomy, optionally promotes selected learnings/passages to the sibling `wisdom` repo via `wisdom "<text>" --book-id <ulid>`, then writes and commits the file. amittiwari.me mounts the repo as a submodule at `external/bookshelf` and bridges the rich schema to its existing `Book` type.

**Tech Stack:** zsh, Crockford-base32 ULIDs, YAML frontmatter, Open Library + Google Books APIs (keyless), GitHub Actions (macOS runner), Next.js + gray-matter (site-side bridge), git submodules, DigitalOcean App Platform redeploy trigger.

---

## File map

**New in `bookshelf/`:**
- `LICENSE` — dual MIT (code) + CC BY 4.0 (corpus)
- `README.md` — quickstart + pointers to docs
- `AGENTS.md` — engine-agnostic rules + push-fallback policy
- `CLAUDE.md` — thin pointer to AGENTS.md
- `.gitignore` — `.bookshelf-session`, `.cache/`, `.DS_Store`, `node_modules/`, `.env`
- `install.sh` — symlink `bin/bookshelf` → `~/bin/bookshelf` + zshrc instructions
- `bin/bookshelf` — zsh dispatcher
- `lib/_shared.zsh` — ulid, slug normalization, repo path, length guard, dedup-by-slug
- `lib/_lookup.zsh` — Open Library + Google Books with HTTP fixture replay
- `lib/_import_helpers.zsh` — `bookshelf_write_record` (frontmatter render + body sections)
- `lib/cmd_capture.zsh` — agent launcher (claude/codex/devin)
- `lib/cmd_ls.zsh` — list with filters
- `lib/cmd_show.zsh` — print one book by slug-prefix
- `lib/cmd_find.zsh` — full-text via rg/grep
- `lib/cmd_edit.zsh` — `$EDITOR` + bump `updated_at`
- `lib/cmd_rm.zsh` — git rm with confirm
- `lib/cmd_reread.zsh` — re-read shortcut, append `## Re-read <year>` section
- `lib/cmd_import_isbn.zsh` — seed skeletons from ISBN list
- `lib/cmd_wisdomify.zsh` — retroactive wisdom promotion
- `books/_categories.yml` — 11 closed categories
- `books/_shelves.yml` — open hint file (initially empty)
- `books/_example.md` — template fixture (referenced by skill + tests; gitignored from corpus listing rules where appropriate)
- `docs/ARCHITECTURE.md` — data model + capture flow + URL ingest
- `docs/USAGE.md` — full CLI reference
- `docs/INSTALL.md` — full install + skill publishing instructions
- `tests/run.zsh` — runner
- `tests/_assert.zsh` — assertions + `setup_temp_repo`
- `tests/cli/test_ulid.zsh`
- `tests/cli/test_slug.zsh`
- `tests/cli/test_repo_resolve.zsh`
- `tests/cli/test_length_guard.zsh`
- `tests/cli/test_lookup_openlibrary.zsh`
- `tests/cli/test_lookup_google_fallback.zsh`
- `tests/cli/test_write_record.zsh`
- `tests/cli/test_capture_kickoff.zsh`
- `tests/cli/test_ls.zsh`
- `tests/cli/test_show.zsh`
- `tests/cli/test_find.zsh`
- `tests/cli/test_edit.zsh`
- `tests/cli/test_rm.zsh`
- `tests/cli/test_reread.zsh`
- `tests/cli/test_import_isbn.zsh`
- `tests/cli/test_wisdomify.zsh`
- `tests/cli/test_categories_closed.zsh`
- `tests/cli/test_shelves_hint.zsh`
- `tests/cli/test_push_gate.zsh`
- `tests/skill/test_skill_fixtures.zsh`
- `tests/fixtures/openlibrary/atomic-habits.json`
- `tests/fixtures/openlibrary/no-match.json`
- `tests/fixtures/googlebooks/atomic-habits.json`
- `.agents/skills/bookshelf-capture/SKILL.md`
- `.agents/skills/bookshelf-capture/REFERENCE.md`
- `.agents/skills/bookshelf-capture/README.md`
- `.github/workflows/ci.yml`
- `.github/workflows/trigger-amittiwari-me.yml`

**Modify in `wisdom/`:**
- `lib/_import_helpers.zsh` — add optional `book_id` rendering (null → omit-from-UI semantics; field always present, value null when absent)
- `lib/cmd_capture.zsh` — accept `--book-id <ulid>` flag, plumb through to write record
- `docs/ARCHITECTURE.md` — schema table adds `book_id`
- `.agents/skills/wisdom-capture/SKILL.md` — note about cross-repo invocation from bookshelf
- `wisdoms/_categories.yml` — no change (closed taxonomy preserved)

**Modify in `amittiwari-me/`:**
- `.gitmodules` — add `external/bookshelf` submodule
- `external/bookshelf` — submodule mount (new)
- `src/lib/types.ts` — extend `Book` with optional rich fields (`authors?`, `wisdomIds?`, `shelves?`, `status?`, `startedAt?`, `finishedAt?`, `recommendedBy?`, `whoShouldRead?`, `subtitle?`, `publishedYear?`, `pages?`, `format?`, `genre?`, `goodreadsUrl?`)
- `src/lib/books.ts` — read from `external/bookshelf/books/` first, fall back to `src/content/books/` for legacy entries; bridge rich → flat schema; map `## Summary` → `excerpt`, strip from body to produce `takeaways`
- `.github/workflows/pages.yml` (if present) or build script — `git submodule update --init --remote external/bookshelf` step

---

## Phase 0: Repo init verification

### Task 0.1: Verify clean git state

**Files:**
- Read: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/.git/HEAD`

- [ ] **Step 1: Check repo exists and is clean**

Run: `cd /Users/amittiwari/Projects/AmitTiwari/bookshelf && git status --porcelain`
Expected: empty output (clean working tree)

- [ ] **Step 2: Confirm branch is main**

Run: `cd /Users/amittiwari/Projects/AmitTiwari/bookshelf && git rev-parse --abbrev-ref HEAD`
Expected: `main`

---

## Phase 1: Bootstrap — license, readme, agent rules

### Task 1.1: Write LICENSE (dual MIT + CC BY 4.0)

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/LICENSE`

- [ ] **Step 1: Write the LICENSE file**

```
Bookshelf — Dual License

Code (everything under bin/, lib/, tests/, .agents/, install.sh, .github/):
  MIT License

  Copyright (c) 2026 Amit Tiwari

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.

Corpus (everything under books/):
  Creative Commons Attribution 4.0 International (CC BY 4.0)
  https://creativecommons.org/licenses/by/4.0/

  You are free to share and adapt the material for any purpose, even
  commercially, under the following terms: you must give appropriate credit,
  provide a link to the license, and indicate if changes were made.
```

### Task 1.2: Write README.md

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/README.md`

- [ ] **Step 1: Write README.md**

```markdown
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
```

### Task 1.3: Write AGENTS.md

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/AGENTS.md`

- [ ] **Step 1: Write AGENTS.md**

Content body (full file — copy verbatim, do not paraphrase):

```markdown
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
```

### Task 1.4: Write CLAUDE.md

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/CLAUDE.md`

- [ ] **Step 1: Write CLAUDE.md**

```markdown
# CLAUDE.md

See `AGENTS.md` for full project conventions. This file exists for backward
compatibility with Claude Code's CLAUDE.md auto-load.

## Pushing changes

Direct push to `main` is policy-blocked. When `git push origin main` is denied
with a direct-push-to-main reason, do NOT surface that as a dead end. Fall
back automatically: create a topic branch at HEAD, reset local `main` to
`origin/main`, push the branch, and open a PR with `gh pr create`. See
`AGENTS.md` → "Pushing changes" for the full rule.
```

### Task 1.5: Write .gitignore

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/.gitignore`

- [ ] **Step 1: Write .gitignore**

```
.bookshelf-session
.cache/
.DS_Store
node_modules/
.env
.env.local
```

### Task 1.6: Commit Phase 1

- [ ] **Step 1: Stage and commit bootstrap files**

```bash
cd /Users/amittiwari/Projects/AmitTiwari/bookshelf
git add LICENSE README.md AGENTS.md CLAUDE.md .gitignore docs/superpowers/plans/2026-05-15-bookshelf-bootstrap.md
git commit -m "chore: bootstrap bookshelf corpus"
```

---

## Phase 2: Corpus scaffolding

### Task 2.1: Write books/_categories.yml

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/books/_categories.yml`

- [ ] **Step 1: Write the categories file**

```yaml
categories:
  - key: engineering
    label: Engineering
    color: electric-blue
    description: software, systems, code, infrastructure
  - key: business
    label: Business
    color: hot-pink
    description: strategy, operations, startups, finance
  - key: leadership
    label: Leadership
    color: warm-coral
    description: managing, hiring, org design, decisions
  - key: product
    label: Product
    color: purple-accent
    description: PM craft, design, UX, roadmaps
  - key: science
    label: Science
    color: cyan-accent
    description: physics, biology, math, popular science
  - key: philosophy
    label: Philosophy
    color: yellow-accent
    description: stoicism, ethics, mind, metaphysics
  - key: psychology
    label: Psychology
    color: lime-green
    description: behavior, cognition, habits, emotion
  - key: history
    label: History
    color: vibrant-orange
    description: biographies, civilizations, wars
  - key: fiction
    label: Fiction
    color: deep-violet
    description: novels, short stories, all genres
  - key: craft
    label: Craft
    color: mint-green
    description: writing craft, taste, mastery, deliberate practice
  - key: life
    label: Life
    color: sun-gold
    description: health, finance, relationships, self
color_pool:
  - blush-pink
  - sky-blue
  - rust-red
```

### Task 2.2: Write books/_shelves.yml

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/books/_shelves.yml`

- [ ] **Step 1: Write the shelves hint file**

```yaml
# Open hint file. The bookshelf-capture skill appends new shelves when the
# user confirms them. Not a closed taxonomy — kept here to avoid typo splits
# (e.g. `nightstand` vs `night-stand`).
shelves: []
```

### Task 2.3: Write books/_example.md template

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/books/_example.md`

- [ ] **Step 1: Write the template fixture**

```markdown
---
id: 01jexampletemplate0000000xx
slug: example-template
title: Example Book Title
subtitle: ""
authors: [Example Author]
isbn13: null
published_year: null
pages: null
language: en
cover_url: null
goodreads_url: null
amazon_url: null
format: null
genre: null
status: read
started_at: null
finished_at: null
rating: null
category: life
tags: []
shelves: []
recommended_by: null
who_should_read: ""
published: false
created_at: 2026-05-15T00:00:00Z
updated_at: 2026-05-15T00:00:00Z
import_origin: template
wisdom_ids: []
---

## Summary

One-paragraph TL;DR of the book.

## Top Learnings

1. **Headline of learning one.** *(provenance tag, e.g. from passage, p.42)*
2. **Headline of learning two.** *(from web — wikipedia)*
3. **Headline of learning three.** *(yours)*

## Favorite Passages

> Quote text here.
> — p.42

> Another quote.
> — Chapter 3

## Notes

Freeform notes section.
```

### Task 2.4: Commit Phase 2

- [ ] **Step 1: Stage and commit corpus scaffolding**

```bash
cd /Users/amittiwari/Projects/AmitTiwari/bookshelf
git add books/_categories.yml books/_shelves.yml books/_example.md
git commit -m "feat: closed category taxonomy + open shelves hint file + template"
```

---

## Phase 3: Test harness scaffolding (must come before TDD on lib/)

### Task 3.1: Write tests/_assert.zsh

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/_assert.zsh`

- [ ] **Step 1: Write assertion helpers**

```zsh
#!/usr/bin/env zsh
# Shared test helpers. Source from each test.

assert_eq() {
  local expected="$1" actual="$2" msg="${3:-values differ}"
  if [[ "$expected" != "$actual" ]]; then
    print -r -- "  FAIL: $msg" >&2
    print -r -- "    expected: $(print -r -- "$expected" | head -c 200)" >&2
    print -r -- "    actual:   $(print -r -- "$actual"   | head -c 200)" >&2
    exit 1
  fi
}

assert_neq() {
  local a="$1" b="$2" msg="${3:-values are equal but should not be}"
  if [[ "$a" == "$b" ]]; then
    print -r -- "  FAIL: $msg" >&2
    exit 1
  fi
}

assert_contains() {
  local haystack="$1" needle="$2" msg="${3:-substring not found}"
  if [[ "$haystack" != *"$needle"* ]]; then
    print -r -- "  FAIL: $msg" >&2
    print -r -- "    looking for: $needle" >&2
    print -r -- "    in:          $(print -r -- "$haystack" | head -c 200)" >&2
    exit 1
  fi
}

assert_not_contains() {
  local haystack="$1" needle="$2" msg="${3:-substring found but should not be}"
  if [[ "$haystack" == *"$needle"* ]]; then
    print -r -- "  FAIL: $msg" >&2
    print -r -- "    found: $needle" >&2
    exit 1
  fi
}

assert_exit_code() {
  local expected="$1" actual="$2" msg="${3:-exit code mismatch}"
  if (( expected != actual )); then
    print -r -- "  FAIL: $msg (expected $expected, got $actual)" >&2
    exit 1
  fi
}

assert_file_exists() {
  local path="$1"
  if [[ ! -e "$path" && ! -L "$path" ]]; then
    print -r -- "  FAIL: file does not exist: $path" >&2
    exit 1
  fi
}

assert_matches() {
  local actual="$1" pattern="$2" msg="${3:-pattern did not match}"
  if ! [[ "$actual" =~ $pattern ]]; then
    print -r -- "  FAIL: $msg" >&2
    print -r -- "    pattern: $pattern" >&2
    print -r -- "    actual:  $actual" >&2
    exit 1
  fi
}

# Fresh temp BOOKSHELF_REPO per test.
setup_temp_repo() {
  local tmp
  tmp=$(mktemp -d -t bookshelf-test.XXXXXX)
  mkdir -p "$tmp/books"
  cp "$BOOKSHELF_SOURCE_REPO/books/_categories.yml" "$tmp/books/_categories.yml"
  cp "$BOOKSHELF_SOURCE_REPO/books/_shelves.yml"   "$tmp/books/_shelves.yml"
  (cd "$tmp" && git init -q && git add -A && git -c user.email=t@t -c user.name=t commit -q -m init)
  print -r -- "$tmp"
}

teardown_temp_repo() {
  local tmp="$1"
  [[ -n "$tmp" && ( "$tmp" == /tmp/* || "$tmp" == /var/folders/* ) ]] && rm -rf "$tmp"
}
```

### Task 3.2: Write tests/run.zsh

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/run.zsh`

- [ ] **Step 1: Write the runner**

```zsh
#!/usr/bin/env zsh
# Test runner. Walks tests/cli, tests/skill; runs each .zsh; reports.
set -u
setopt NULL_GLOB
script_path=${0:A}
repo_root=${script_path:h:h}
export BOOKSHELF_SOURCE_REPO="$repo_root"

pass=0
fail=0
skip=0
failed_tests=()

for dir in tests/cli tests/skill; do
  [[ -d "$repo_root/$dir" ]] || continue
  for test in "$repo_root"/$dir/test_*.zsh; do
    [[ -f "$test" ]] || continue
    name="${test#$repo_root/}"
    if zsh "$test" >/tmp/bookshelf-test.out 2>&1; then
      if grep -q '^SKIP:' /tmp/bookshelf-test.out; then
        (( skip++ ))
        print -r -- "  SKIP $name"
      else
        (( pass++ ))
        print -r -- "  PASS $name"
      fi
    else
      (( fail++ ))
      failed_tests+=("$name")
      print -r -- "  FAIL $name"
      print -r -- "    ---"
      sed 's/^/    /' /tmp/bookshelf-test.out
      print -r -- "    ---"
    fi
  done
done

print
print -r -- "$pass passed, $fail failed, $skip skipped"
exit $(( fail > 0 ? 1 : 0 ))
```

- [ ] **Step 2: Make runner executable + smoke-test on empty test dir**

```bash
chmod +x /Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/run.zsh
zsh /Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/run.zsh
```

Expected: `0 passed, 0 failed, 0 skipped`

- [ ] **Step 3: Commit test harness**

```bash
cd /Users/amittiwari/Projects/AmitTiwari/bookshelf
git add tests/run.zsh tests/_assert.zsh
git commit -m "test: harness — runner + assertions + temp-repo helpers"
```

---

## Phase 4: lib/_shared.zsh (TDD)

### Task 4.1: ULID test + impl

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/cli/test_ulid.zsh`
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/lib/_shared.zsh`

- [ ] **Step 1: Write failing test**

```zsh
#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"

id=$(bookshelf_ulid)
assert_eq 26 "${#id}" "ULID length must be 26"
[[ "$id" =~ '^[0-9a-hjkmnp-tv-z]{26}$' ]] || { print -r -- "FAIL: ULID alphabet"; exit 1; }

a=$(bookshelf_ulid); b=$(bookshelf_ulid)
assert_neq "$a" "$b" "Two ULIDs must differ"

sleep 0.01
c=$(bookshelf_ulid)
[[ "$a" < "$c" ]] || { print -r -- "FAIL: ULID lexicographic order"; exit 1; }
```

- [ ] **Step 2: Run — expect FAIL (no _shared.zsh yet)**

Run: `zsh /Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/cli/test_ulid.zsh`
Expected: error `no such file`

- [ ] **Step 3: Create lib/_shared.zsh with ULID, slug, repo-path, length-guard**

```zsh
#!/usr/bin/env zsh
# Shared helpers for bookshelf CLI. Functions are prefixed with `bookshelf_`.

_BOOKSHELF_ULID_ALPHABET="0123456789abcdefghjkmnpqrstvwxyz"

bookshelf_ulid() {
  local ms hex i v out=""
  if (( $+commands[gdate] )); then
    ms=$(gdate +%s%3N)
  else
    local s ns
    s=$(date +%s)
    ns=$(date +%N 2>/dev/null)
    if [[ -z "$ns" || "$ns" == "N" ]]; then
      ms=$((s * 1000))
    else
      ms=$((s * 1000 + ${ns:0:3}))
    fi
  fi
  local t=$ms
  for i in {1..10}; do
    v=$(( t % 32 ))
    out="${_BOOKSHELF_ULID_ALPHABET:$v:1}${out}"
    t=$(( t / 32 ))
  done
  hex=$(head -c 10 /dev/urandom | od -An -tx1 | tr -d ' \n')
  local bits="" b
  for (( i=0; i<${#hex}; i+=2 )); do
    b=$(printf '%08d' "$(echo "obase=2; ibase=16; ${(U)hex[$((i+1)),$((i+2))]}" | bc)")
    bits+="$b"
  done
  local r=""
  for (( i=0; i<80; i+=5 )); do
    v=$(( 2#${bits:$i:5} ))
    r+="${_BOOKSHELF_ULID_ALPHABET:$v:1}"
  done
  print -r -- "${out}${r}"
}

_BOOKSHELF_DEFAULT_REPO="${HOME}/Projects/AmitTiwari/bookshelf"

bookshelf_repo_path() {
  local strict="${BOOKSHELF_REPO_STRICT:-0}"
  local p="${BOOKSHELF_REPO:-$_BOOKSHELF_DEFAULT_REPO}"
  if [[ "$strict" == "1" && ! -d "$p/.git" ]]; then
    print -r -- "bookshelf: repo not found at $p (set BOOKSHELF_REPO)" >&2
    return 2
  fi
  print -r -- "$p"
}

bookshelf_cd_repo() {
  local p
  p=$(BOOKSHELF_REPO_STRICT=1 bookshelf_repo_path) || return $?
  cd "$p" || return 2
}

# Slug: lowercase, ASCII-transliterated, strip leading article + subtitle, kebab,
# cap 80 chars, then append `-<author-last-kebab>` (caller responsibility to
# pass the cleaned author last).
#
# Args: $1 = title, $2 = author last name
bookshelf_slug() {
  local title="$1" author_last="$2"
  local s
  # transliterate Unicode to ASCII; fall back to original on iconv failure
  if (( $+commands[iconv] )); then
    s=$(print -r -- "$title" | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null) || s="$title"
  else
    s="$title"
  fi
  # drop subtitle: anything after `:` or ` — ` or ` - `
  s=$(print -r -- "$s" | sed -E 's/[:—].*$//; s/ - .*$//')
  # lowercase
  s=$(print -r -- "$s" | tr '[:upper:]' '[:lower:]')
  # strip leading article
  s=$(print -r -- "$s" | sed -E 's/^(the|a|an) +//')
  # non-alphanum -> hyphen
  s=$(print -r -- "$s" | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')
  # cap title portion
  s="${s:0:80}"
  if [[ -n "$author_last" ]]; then
    local al
    al=$(print -r -- "$author_last" \
      | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null || print -r -- "$author_last")
    al=$(print -r -- "$al" | tr '[:upper:]' '[:lower:]' \
      | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')
    [[ -n "$al" ]] && s="${s}-${al}"
  fi
  print -r -- "$s"
}

_BOOKSHELF_TITLE_MIN=2
_BOOKSHELF_TITLE_MAX=500

bookshelf_check_title() {
  local title="$1"
  local n=${#title}
  if (( n < _BOOKSHELF_TITLE_MIN )); then
    print -r -- "bookshelf: title too short ($n chars; min $_BOOKSHELF_TITLE_MIN)" >&2
    return 6
  fi
  if (( n > _BOOKSHELF_TITLE_MAX )); then
    print -r -- "bookshelf: title too long ($n chars; max $_BOOKSHELF_TITLE_MAX)" >&2
    return 6
  fi
  return 0
}

# Find an existing book file by slug. Prints path on stdout, empty if none.
bookshelf_find_by_slug() {
  local slug="$1"
  local repo="${2:-$(bookshelf_repo_path)}"
  local f="$repo/books/$slug.md"
  [[ -f "$f" ]] && print -r -- "$f"
}
```

- [ ] **Step 4: Run test — expect PASS**

Run: `zsh /Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/cli/test_ulid.zsh`
Expected: clean exit (no FAIL output)

### Task 4.2: Slug test

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/cli/test_slug.zsh`

- [ ] **Step 1: Write the test**

```zsh
#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"

# Simple title + author
assert_eq "atomic-habits-clear" "$(bookshelf_slug "Atomic Habits" "Clear")"

# Strip leading article
assert_eq "pragmatic-programmer-hunt" "$(bookshelf_slug "The Pragmatic Programmer" "Hunt")"

# Strip subtitle
assert_eq "thinking-fast-and-slow-kahneman" "$(bookshelf_slug "Thinking, Fast and Slow: A Revolutionary Look" "Kahneman")"

# Em-dash subtitle stripped
assert_eq "flow-csikszentmihalyi" "$(bookshelf_slug "Flow — The Psychology of Optimal Experience" "Csikszentmihalyi")"

# Unicode transliteration in author
result="$(bookshelf_slug "Kokoro" "Sōseki")"
assert_eq "kokoro-soseki" "$result"

# No author falls back to title only
assert_eq "atomic-habits" "$(bookshelf_slug "Atomic Habits" "")"
```

- [ ] **Step 2: Run — expect PASS**

Run: `zsh /Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/cli/test_slug.zsh`
Expected: clean exit

### Task 4.3: Repo-resolve test

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/cli/test_repo_resolve.zsh`

- [ ] **Step 1: Write the test**

```zsh
#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"

# Default path (no env override)
unset BOOKSHELF_REPO
result=$(bookshelf_repo_path)
assert_contains "$result" "bookshelf" "default path mentions bookshelf"

# Env override wins
export BOOKSHELF_REPO=/tmp/nope
result=$(bookshelf_repo_path)
assert_eq "/tmp/nope" "$result"

# Strict mode fails on missing dir
unset BOOKSHELF_REPO
export BOOKSHELF_REPO=/tmp/definitely-does-not-exist-xxx
BOOKSHELF_REPO_STRICT=1 bookshelf_repo_path 2>/dev/null && rc=0 || rc=$?
assert_eq 2 "$rc" "strict mode should return 2"
unset BOOKSHELF_REPO
```

- [ ] **Step 2: Run — expect PASS**

Run: `zsh /Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/cli/test_repo_resolve.zsh`

### Task 4.4: Length-guard test

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/cli/test_length_guard.zsh`

- [ ] **Step 1: Write the test**

```zsh
#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"

# Below min
bookshelf_check_title "A" 2>/dev/null && rc=0 || rc=$?
assert_eq 6 "$rc"

# Within bounds
bookshelf_check_title "Atomic Habits" && rc=0 || rc=$?
assert_eq 0 "$rc"

# Over max
long_title=$(printf 'x%.0s' {1..501})
bookshelf_check_title "$long_title" 2>/dev/null && rc=0 || rc=$?
assert_eq 6 "$rc"
```

- [ ] **Step 2: Run — expect PASS**

### Task 4.5: Commit Phase 4

- [ ] **Step 1: Run all tests so far**

Run: `zsh /Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/run.zsh`
Expected: `4 passed, 0 failed`

- [ ] **Step 2: Commit**

```bash
cd /Users/amittiwari/Projects/AmitTiwari/bookshelf
git add lib/_shared.zsh tests/cli/test_ulid.zsh tests/cli/test_slug.zsh tests/cli/test_repo_resolve.zsh tests/cli/test_length_guard.zsh
git commit -m "feat(lib): _shared.zsh — ulid, slug, repo path, length guard"
```

---

## Phase 5: lib/_lookup.zsh (TDD with HTTP fixtures)

### Task 5.1: Fixture files

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/fixtures/openlibrary/atomic-habits.json`
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/fixtures/openlibrary/no-match.json`
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/fixtures/googlebooks/atomic-habits.json`

- [ ] **Step 1: Write Open Library success fixture**

`tests/fixtures/openlibrary/atomic-habits.json`:

```json
{
  "numFound": 1,
  "docs": [
    {
      "key": "/works/OL17877423W",
      "title": "Atomic Habits",
      "author_name": ["James Clear"],
      "first_publish_year": 2018,
      "number_of_pages_median": 320,
      "isbn": ["9780735211292"],
      "cover_i": 9259256,
      "language": ["eng"]
    }
  ]
}
```

- [ ] **Step 2: Write Open Library no-match fixture**

`tests/fixtures/openlibrary/no-match.json`:

```json
{
  "numFound": 0,
  "docs": []
}
```

- [ ] **Step 3: Write Google Books success fixture**

`tests/fixtures/googlebooks/atomic-habits.json`:

```json
{
  "totalItems": 1,
  "items": [
    {
      "id": "fFCjDwAAQBAJ",
      "volumeInfo": {
        "title": "Atomic Habits",
        "subtitle": "An Easy & Proven Way to Build Good Habits & Break Bad Ones",
        "authors": ["James Clear"],
        "publishedDate": "2018-10-16",
        "pageCount": 320,
        "language": "en",
        "industryIdentifiers": [{"type": "ISBN_13", "identifier": "9780735211292"}],
        "imageLinks": {"thumbnail": "http://books.google.com/books/content?id=fFCjDwAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl"}
      }
    }
  ]
}
```

### Task 5.2: Open Library lookup test + impl

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/cli/test_lookup_openlibrary.zsh`
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/lib/_lookup.zsh`

- [ ] **Step 1: Write failing test**

```zsh
#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"
source "$repo_root/lib/_lookup.zsh"

export BOOKSHELF_LOOKUP_FIXTURES="$repo_root/tests/fixtures"

# Hit: returns JSON with title/authors/year
result=$(bookshelf_lookup_openlibrary "Atomic Habits")
assert_contains "$result" "Atomic Habits"
assert_contains "$result" "James Clear"
assert_contains "$result" "2018"

# No-match: empty docs array
result=$(bookshelf_lookup_openlibrary "Zzz No Match Zzz")
assert_contains "$result" '"numFound": 0'
```

- [ ] **Step 2: Run — expect FAIL (no _lookup.zsh)**

Run: `zsh /Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/cli/test_lookup_openlibrary.zsh`

- [ ] **Step 3: Create lib/_lookup.zsh**

```zsh
#!/usr/bin/env zsh
# Book metadata lookup. Open Library primary, Google Books fallback.
# If BOOKSHELF_LOOKUP_FIXTURES is set, reads from filesystem instead of network.

# Slugify title for fixture filename: lowercase, kebab, non-alphanum -> hyphen.
_bookshelf_fixture_slug() {
  print -r -- "$1" \
    | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

bookshelf_lookup_openlibrary() {
  local title="$1"
  local fixtures="${BOOKSHELF_LOOKUP_FIXTURES:-}"
  if [[ -n "$fixtures" ]]; then
    local slug
    slug=$(_bookshelf_fixture_slug "$title")
    local f="$fixtures/openlibrary/$slug.json"
    if [[ -f "$f" ]]; then
      cat "$f"
      return 0
    fi
    cat "$fixtures/openlibrary/no-match.json"
    return 0
  fi
  if ! (( $+commands[curl] )); then
    print -r -- "bookshelf: curl required for Open Library lookup" >&2
    return 4
  fi
  local q
  q=$(print -r -- "$title" | sed -E 's/ /+/g')
  curl -sS --max-time 8 "https://openlibrary.org/search.json?title=${q}&limit=3"
}

bookshelf_lookup_googlebooks() {
  local title="$1"
  local fixtures="${BOOKSHELF_LOOKUP_FIXTURES:-}"
  if [[ -n "$fixtures" ]]; then
    local slug
    slug=$(_bookshelf_fixture_slug "$title")
    local f="$fixtures/googlebooks/$slug.json"
    if [[ -f "$f" ]]; then
      cat "$f"
      return 0
    fi
    print -r -- '{"totalItems": 0, "items": []}'
    return 0
  fi
  if ! (( $+commands[curl] )); then
    print -r -- "bookshelf: curl required for Google Books lookup" >&2
    return 4
  fi
  local q
  q=$(print -r -- "$title" | sed -E 's/ /+/g')
  local url="https://www.googleapis.com/books/v1/volumes?q=intitle:${q}&maxResults=3"
  [[ -n "${GOOGLE_BOOKS_API_KEY:-}" ]] && url+="&key=${GOOGLE_BOOKS_API_KEY}"
  curl -sS --max-time 8 "$url"
}

# Combined lookup: try Open Library; if numFound=0, fall through to Google Books.
# Echoes a normalized JSON object on stdout:
#   {"source": "openlibrary|googlebooks|none", "title": ..., "authors": [...], ...}
# Requires jq.
bookshelf_lookup() {
  local title="$1"
  if ! (( $+commands[jq] )); then
    print -r -- "bookshelf: jq required to normalize lookup output" >&2
    return 4
  fi
  local ol gb
  ol=$(bookshelf_lookup_openlibrary "$title") || return $?
  local n
  n=$(print -r -- "$ol" | jq -r '.numFound // 0')
  if (( n > 0 )); then
    print -r -- "$ol" | jq '{
      source: "openlibrary",
      title: .docs[0].title,
      authors: (.docs[0].author_name // []),
      published_year: .docs[0].first_publish_year,
      pages: .docs[0].number_of_pages_median,
      isbn13: ((.docs[0].isbn // []) | map(select(length == 13)) | .[0]),
      cover_id: .docs[0].cover_i,
      language: ((.docs[0].language // []) | .[0])
    }'
    return 0
  fi
  gb=$(bookshelf_lookup_googlebooks "$title") || return $?
  local m
  m=$(print -r -- "$gb" | jq -r '.totalItems // 0')
  if (( m > 0 )); then
    print -r -- "$gb" | jq '{
      source: "googlebooks",
      title: .items[0].volumeInfo.title,
      subtitle: .items[0].volumeInfo.subtitle,
      authors: (.items[0].volumeInfo.authors // []),
      published_year: (.items[0].volumeInfo.publishedDate | (.[0:4] // null) | tonumber? // null),
      pages: .items[0].volumeInfo.pageCount,
      isbn13: ((.items[0].volumeInfo.industryIdentifiers // []) | map(select(.type == "ISBN_13")) | .[0].identifier),
      cover_url: .items[0].volumeInfo.imageLinks.thumbnail,
      language: .items[0].volumeInfo.language
    }'
    return 0
  fi
  print -r -- '{"source": "none"}'
}
```

- [ ] **Step 4: Run test — expect PASS**

### Task 5.3: Google Books fallback test

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/cli/test_lookup_google_fallback.zsh`

- [ ] **Step 1: Write test**

```zsh
#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"
source "$repo_root/lib/_lookup.zsh"

export BOOKSHELF_LOOKUP_FIXTURES="$repo_root/tests/fixtures"

if ! (( $+commands[jq] )); then
  print -r -- "SKIP: jq not installed"
  exit 0
fi

# Open Library hit short-circuits
result=$(bookshelf_lookup "Atomic Habits")
assert_contains "$result" "openlibrary"
assert_contains "$result" "Atomic Habits"

# When Open Library has no match, falls through to Google Books
# (we route by the fixture slug — "Zzz No Match" slugs to a missing file =>
#  no-match fixture for OL, and same-slug-miss for GB => "none")
result=$(bookshelf_lookup "Zzz No Match")
assert_contains "$result" "\"source\""
```

- [ ] **Step 2: Run — expect PASS**

### Task 5.4: Commit Phase 5

- [ ] **Step 1: Commit lookup**

```bash
cd /Users/amittiwari/Projects/AmitTiwari/bookshelf
git add lib/_lookup.zsh tests/cli/test_lookup_openlibrary.zsh tests/cli/test_lookup_google_fallback.zsh tests/fixtures/
git commit -m "feat(lib): _lookup.zsh — open library + google books with fixture replay"
```

---

## Phase 6: lib/_import_helpers.zsh (TDD)

### Task 6.1: Write record test + impl

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/cli/test_write_record.zsh`
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/lib/_import_helpers.zsh`

- [ ] **Step 1: Write failing test**

```zsh
#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"
source "$repo_root/lib/_import_helpers.zsh"

tmp=$(setup_temp_repo)
export BOOKSHELF_REPO="$tmp"

out=$(bookshelf_write_record \
  --title "Atomic Habits" \
  --slug "atomic-habits-clear" \
  --authors-csv "James Clear" \
  --category "craft" \
  --tags-csv "habits,behavior-change" \
  --shelves-csv "nightstand,kindle" \
  --status "read" \
  --finished-at "2026-05-01" \
  --rating "5" \
  --published-year "2018" \
  --pages "320" \
  --isbn13 "9780735211292" \
  --summary "A guide to building good habits." \
  --learnings "1. **Compound habits.** *(yours)*\n2. **Identity > outcome.** *(from web)*" \
  --passages "> Habits are the compound interest of self-improvement.\n> — p.18" \
  --notes "" \
  --origin "manual")

assert_file_exists "$out"
content=$(cat "$out")
assert_contains "$content" "id: 01"
assert_contains "$content" "slug: atomic-habits-clear"
assert_contains "$content" 'title: "Atomic Habits"'
assert_contains "$content" "authors: [James Clear]"
assert_contains "$content" "category: craft"
assert_contains "$content" "tags: [habits, behavior-change]"
assert_contains "$content" "shelves: [nightstand, kindle]"
assert_contains "$content" "status: read"
assert_contains "$content" "finished_at: 2026-05-01"
assert_contains "$content" "rating: 5"
assert_contains "$content" "isbn13: \"9780735211292\""
assert_contains "$content" "## Summary"
assert_contains "$content" "A guide to building good habits."
assert_contains "$content" "## Top Learnings"
assert_contains "$content" "Compound habits"
assert_contains "$content" "## Favorite Passages"
assert_contains "$content" "compound interest"
assert_contains "$content" "wisdom_ids: []"

teardown_temp_repo "$tmp"
```

- [ ] **Step 2: Run — expect FAIL**

- [ ] **Step 3: Implement lib/_import_helpers.zsh**

```zsh
#!/usr/bin/env zsh
# Render a book entry to books/<slug>.md with full frontmatter + body sections.
# Echoes path on stdout.

_bookshelf_yaml_array() {
  local csv="$1"
  if [[ -z "$csv" ]]; then
    print -r -- "[]"
    return
  fi
  local out="[" first=1
  local IFS=','
  local item
  for item in ${=csv}; do
    item="${item## }"; item="${item%% }"
    if (( first )); then
      out+="$item"; first=0
    else
      out+=", $item"
    fi
  done
  out+="]"
  print -r -- "$out"
}

_bookshelf_yaml_quote() {
  local v="$1"
  if [[ -z "$v" ]]; then print -r -- '""'; return; fi
  if [[ "$v" == *:* || "$v" == *\#* || "$v" == \-* || "$v" == \?* ]]; then
    v="${v//\"/\\\"}"
    print -r -- "\"$v\""
  else
    print -r -- "\"$v\""
  fi
}

bookshelf_write_record() {
  local title="" subtitle="" slug="" authors_csv="" isbn13="" published_year="" pages=""
  local language="en" cover_url="" goodreads_url="" amazon_url="" format="" genre=""
  local status="read" started_at="" finished_at="" rating="" category="life"
  local tags_csv="" shelves_csv="" recommended_by="" who_should_read="" published=""
  local summary="" learnings="" passages="" notes="" origin="manual"
  local wisdom_ids_csv=""

  while (( $# )); do
    case "$1" in
      --title)            title="$2"; shift 2 ;;
      --subtitle)         subtitle="$2"; shift 2 ;;
      --slug)             slug="$2"; shift 2 ;;
      --authors-csv)      authors_csv="$2"; shift 2 ;;
      --isbn13)           isbn13="$2"; shift 2 ;;
      --published-year)   published_year="$2"; shift 2 ;;
      --pages)            pages="$2"; shift 2 ;;
      --language)         language="$2"; shift 2 ;;
      --cover-url)        cover_url="$2"; shift 2 ;;
      --goodreads-url)    goodreads_url="$2"; shift 2 ;;
      --amazon-url)       amazon_url="$2"; shift 2 ;;
      --format)           format="$2"; shift 2 ;;
      --genre)            genre="$2"; shift 2 ;;
      --status)           status="$2"; shift 2 ;;
      --started-at)       started_at="$2"; shift 2 ;;
      --finished-at)      finished_at="$2"; shift 2 ;;
      --rating)           rating="$2"; shift 2 ;;
      --category)         category="$2"; shift 2 ;;
      --tags-csv)         tags_csv="$2"; shift 2 ;;
      --shelves-csv)      shelves_csv="$2"; shift 2 ;;
      --recommended-by)   recommended_by="$2"; shift 2 ;;
      --who-should-read)  who_should_read="$2"; shift 2 ;;
      --published)        published="$2"; shift 2 ;;
      --summary)          summary="$2"; shift 2 ;;
      --learnings)        learnings="$2"; shift 2 ;;
      --passages)         passages="$2"; shift 2 ;;
      --notes)            notes="$2"; shift 2 ;;
      --origin)           origin="$2"; shift 2 ;;
      --wisdom-ids-csv)   wisdom_ids_csv="$2"; shift 2 ;;
      *) print -r -- "write_record: unknown flag $1" >&2; return 1 ;;
    esac
  done

  [[ -z "$title" || -z "$slug" ]] && { print -r -- "write_record: --title and --slug required" >&2; return 1; }

  # Default `published` based on status
  if [[ -z "$published" ]]; then
    if [[ "$status" == "read" ]]; then published="true"; else published="false"; fi
  fi

  local repo id now
  repo=$(bookshelf_repo_path) || return 2
  id=$(bookshelf_ulid)
  now=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
  mkdir -p "$repo/books"
  local out="$repo/books/$slug.md"

  local authors_yaml tags_yaml shelves_yaml wisdom_yaml
  authors_yaml=$(_bookshelf_yaml_array "$authors_csv")
  tags_yaml=$(_bookshelf_yaml_array "$tags_csv")
  shelves_yaml=$(_bookshelf_yaml_array "$shelves_csv")
  wisdom_yaml=$(_bookshelf_yaml_array "$wisdom_ids_csv")

  {
    print -r -- "---"
    print -r -- "id: $id"
    print -r -- "slug: $slug"
    print -r -- "title: $(_bookshelf_yaml_quote "$title")"
    print -r -- "subtitle: $(_bookshelf_yaml_quote "$subtitle")"
    print -r -- "authors: $authors_yaml"
    print -r -- "isbn13: ${isbn13:+\"$isbn13\"}${isbn13:-null}"
    print -r -- "published_year: ${published_year:-null}"
    print -r -- "pages: ${pages:-null}"
    print -r -- "language: $language"
    print -r -- "cover_url: ${cover_url:+\"$cover_url\"}${cover_url:-null}"
    print -r -- "goodreads_url: ${goodreads_url:+\"$goodreads_url\"}${goodreads_url:-null}"
    print -r -- "amazon_url: ${amazon_url:+\"$amazon_url\"}${amazon_url:-null}"
    print -r -- "format: ${format:+\"$format\"}${format:-null}"
    print -r -- "genre: ${genre:+\"$genre\"}${genre:-null}"
    print -r -- "status: $status"
    print -r -- "started_at: ${started_at:-null}"
    print -r -- "finished_at: ${finished_at:-null}"
    print -r -- "rating: ${rating:-null}"
    print -r -- "category: $category"
    print -r -- "tags: $tags_yaml"
    print -r -- "shelves: $shelves_yaml"
    print -r -- "recommended_by: ${recommended_by:+\"$recommended_by\"}${recommended_by:-null}"
    print -r -- "who_should_read: $(_bookshelf_yaml_quote "$who_should_read")"
    print -r -- "published: $published"
    print -r -- "created_at: $now"
    print -r -- "updated_at: $now"
    print -r -- "import_origin: $origin"
    print -r -- "wisdom_ids: $wisdom_yaml"
    print -r -- "---"
    print -r --
    print -r -- "## Summary"
    print -r --
    [[ -n "$summary" ]] && print -r -- "$summary" || print -r -- "_TBD_"
    print -r --
    print -r -- "## Top Learnings"
    print -r --
    if [[ -n "$learnings" ]]; then
      print -r -- "${learnings//\\n/$'\n'}"
    fi
    print -r --
    print -r -- "## Favorite Passages"
    print -r --
    if [[ -n "$passages" ]]; then
      print -r -- "${passages//\\n/$'\n'}"
    fi
    print -r --
    print -r -- "## Notes"
    print -r --
    [[ -n "$notes" ]] && print -r -- "$notes"
  } > "$out"

  print -r -- "$out"
}
```

- [ ] **Step 4: Run test — expect PASS**

- [ ] **Step 5: Commit**

```bash
cd /Users/amittiwari/Projects/AmitTiwari/bookshelf
git add lib/_import_helpers.zsh tests/cli/test_write_record.zsh
git commit -m "feat(lib): _import_helpers.zsh — bookshelf_write_record"
```

---

## Phase 7: bin/bookshelf dispatcher + capture launcher

### Task 7.1: Capture command + dispatcher

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/lib/cmd_capture.zsh`
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/bin/bookshelf`
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/cli/test_capture_kickoff.zsh`

- [ ] **Step 1: Write the capture test**

```zsh
#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"

# Stub the engine launcher and verify routing.
fake_claude() {
  local payload
  payload=$(cat)
  print -r -- "$payload" > /tmp/bookshelf-test-payload.txt
}

tmp=$(mktemp -d -t bookshelf-bin.XXXXXX)
mkdir -p "$tmp/bin"
print -r -- '#!/usr/bin/env zsh
fake_claude() { cat > /tmp/bookshelf-test-payload.txt; }
fake_claude
' > "$tmp/bin/claude"
chmod +x "$tmp/bin/claude"
export PATH="$tmp/bin:$PATH"
export BOOKSHELF_REPO="$tmp"
export BOOKSHELF_ENGINE="claude"
mkdir -p "$tmp/books"
(cd "$tmp" && git init -q && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init)

# Run dispatcher with a title
"$repo_root/bin/bookshelf" "Atomic Habits"
payload=$(cat /tmp/bookshelf-test-payload.txt 2>/dev/null || true)
assert_contains "$payload" "Atomic Habits"
assert_contains "$payload" "bookshelf-capture"

# Run with no args — kickoff prompt
"$repo_root/bin/bookshelf"
payload=$(cat /tmp/bookshelf-test-payload.txt 2>/dev/null || true)
assert_contains "$payload" "bookshelf-capture"

rm -rf "$tmp"
rm -f /tmp/bookshelf-test-payload.txt
```

- [ ] **Step 2: Run — expect FAIL**

- [ ] **Step 3: Create lib/cmd_capture.zsh**

```zsh
#!/usr/bin/env zsh
# Capture command: launches an agent session in the bookshelf repo.

_BOOKSHELF_EDIT_TEMPLATE='# Type the title (and optional author) of the book below.
# Lines starting with `#` are ignored.
# When done, save and exit. Empty -> cancel.

'

_BOOKSHELF_KICKOFF_PROMPT='I want to log a book onto my bookshelf. Engage the bookshelf-capture skill and ask me for the title.'

_bookshelf_launch_engine() {
  local engine="$1"; shift
  local title="$1"; shift
  local author_hint="$1"
  local repo
  repo=$(bookshelf_repo_path) || return 2
  cd "$repo" || return 2

  local first_turn
  if [[ -n "$title" ]]; then
    first_turn="Log this book onto my bookshelf using the bookshelf-capture skill. Title: $title"
    [[ -n "$author_hint" ]] && first_turn+=$'\nAuthor hint: '"$author_hint"
  else
    first_turn="$_BOOKSHELF_KICKOFF_PROMPT"
  fi

  case "$engine" in
    claude)
      if (( $+commands[claude] )); then
        print -r -- "$first_turn" | claude
      else
        print -r -- "bookshelf: 'claude' CLI not found on \$PATH" >&2
        return 3
      fi
      ;;
    codex)
      if (( $+commands[codex] )); then
        print -r -- "$first_turn" | codex
      else
        print -r -- "bookshelf: 'codex' CLI not found on \$PATH" >&2
        return 3
      fi
      ;;
    devin)
      if (( $+commands[devin] )); then
        devin --task "$first_turn"
      else
        print -r -- "bookshelf: 'devin' CLI not found on \$PATH" >&2
        return 3
      fi
      ;;
    *)
      print -r -- "bookshelf: unknown engine '$engine' (use claude|codex|devin)" >&2
      return 1
      ;;
  esac
}

_bookshelf_capture() {
  local engine="${BOOKSHELF_ENGINE:-claude}"
  local title="" author_hint=""
  local use_editor=0 from_stdin=0

  while (( $# )); do
    case "$1" in
      --engine)    engine="$2"; shift 2 ;;
      --engine=*)  engine="${1#--engine=}"; shift ;;
      --author)    author_hint="$2"; shift 2 ;;
      --author=*)  author_hint="${1#--author=}"; shift ;;
      -e)          use_editor=1; shift ;;
      -)           from_stdin=1; shift ;;
      --)          shift; break ;;
      -*)          print -r -- "bookshelf capture: unknown flag $1" >&2; return 1 ;;
      *)
        if [[ -z "$title" ]]; then title="$1"; else title="$title $1"; fi
        shift ;;
    esac
  done

  if (( from_stdin )); then
    title=$(cat)
  elif (( use_editor )); then
    local tmp
    tmp=$(mktemp -t bookshelf-edit.XXXXXX.md)
    print -r -- "$_BOOKSHELF_EDIT_TEMPLATE" > "$tmp"
    "${BOOKSHELF_EDITOR:-${EDITOR:-vi}}" "$tmp"
    title=$(grep -v '^#' "$tmp" | sed -E '/./,$!d' | sed -E ':a;$!N;$!ba;s/\n+$//')
    rm -f "$tmp"
  fi

  if [[ -n "$title" ]]; then
    bookshelf_check_title "$title" || return $?
  fi

  _bookshelf_launch_engine "$engine" "$title" "$author_hint"
}
```

- [ ] **Step 4: Create bin/bookshelf dispatcher**

```zsh
#!/usr/bin/env zsh
# Bookshelf CLI dispatcher. Routes to lib/cmd_*.zsh modules.
set -u
script_path=${0:A}
repo_root=${script_path:h:h}

source "$repo_root/lib/_shared.zsh"
for f in "$repo_root"/lib/cmd_*.zsh(N); do
  source "$f"
done

_BOOKSHELF_VERSION="0.1.0"

usage() {
  cat <<'EOF'
bookshelf — log books and the learnings you took from them

USAGE
  bookshelf                          launch agent session; skill auto-engages
  bookshelf "<title>"                launch agent with title prefilled
  bookshelf "<title>" --author "..." with author hint
  bookshelf -                        read title from stdin
  bookshelf -e                       open $EDITOR with a template
  bookshelf --engine <name>          claude | codex | devin (default: claude)

  bookshelf ls [--category KEY] [--shelf KEY] [--status S] [--year N] [--limit N]
  bookshelf show <slug-prefix>
  bookshelf find <query>
  bookshelf edit <slug-prefix>
  bookshelf rm <slug-prefix>
  bookshelf reread <slug-prefix>
  bookshelf import-isbn <isbn> [<isbn>...]
  bookshelf wisdomify <slug-prefix>

  bookshelf help | --help | -h
  bookshelf version | --version | -V

ENVIRONMENT
  BOOKSHELF_REPO     absolute path to repo (default: ~/Projects/AmitTiwari/bookshelf)
  BOOKSHELF_ENGINE   claude | codex | devin (default: claude)
  BOOKSHELF_EDITOR   overrides $EDITOR for -e and edit
  BOOKSHELF_NO_PUSH  if set, skill skips push prompts

See docs/USAGE.md for the full reference.
EOF
}

version() { print -r -- "bookshelf $_BOOKSHELF_VERSION"; }

main() {
  if (( $# == 0 )); then
    _bookshelf_capture
    return $?
  fi
  case "$1" in
    -h|--help|help)        usage; return 0 ;;
    -V|--version|version)  version; return 0 ;;
    ls)            shift; _bookshelf_ls "$@" ;;
    show)          shift; _bookshelf_show "$@" ;;
    find)          shift; _bookshelf_find "$@" ;;
    edit)          shift; _bookshelf_edit "$@" ;;
    rm|remove)     shift; _bookshelf_rm "$@" ;;
    reread)        shift; _bookshelf_reread "$@" ;;
    import-isbn)   shift; _bookshelf_import_isbn "$@" ;;
    wisdomify)     shift; _bookshelf_wisdomify "$@" ;;
    --engine|-|-e|--author) _bookshelf_capture "$@" ;;
    -*) print -r -- "bookshelf: unknown flag: $1" >&2; usage >&2; return 1 ;;
    *)
      _bookshelf_capture "$@" ;;
  esac
}

main "$@"
```

- [ ] **Step 5: Make bookshelf executable**

```bash
chmod +x /Users/amittiwari/Projects/AmitTiwari/bookshelf/bin/bookshelf
```

- [ ] **Step 6: Run test — expect PASS**

Run: `zsh /Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/cli/test_capture_kickoff.zsh`

- [ ] **Step 7: Commit**

```bash
cd /Users/amittiwari/Projects/AmitTiwari/bookshelf
git add bin/bookshelf lib/cmd_capture.zsh tests/cli/test_capture_kickoff.zsh
git commit -m "feat(cli): bookshelf dispatcher + capture command"
```

---

## Phase 8: cmd_ls.zsh (TDD)

### Task 8.1: ls test + impl

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/cli/test_ls.zsh`
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/lib/cmd_ls.zsh`

- [ ] **Step 1: Write the failing test**

```zsh
#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"
source "$repo_root/lib/_import_helpers.zsh"
source "$repo_root/lib/cmd_ls.zsh"

tmp=$(setup_temp_repo)
export BOOKSHELF_REPO="$tmp"

# Empty list
result=$(_bookshelf_ls)
assert_contains "$result" "no books yet"

# Seed two
bookshelf_write_record --title "Atomic Habits" --slug "atomic-habits-clear" \
  --authors-csv "James Clear" --category "craft" --tags-csv "habits" \
  --shelves-csv "nightstand" --status "read" --finished-at "2026-04-01" >/dev/null
sleep 0.01
bookshelf_write_record --title "Sapiens" --slug "sapiens-harari" \
  --authors-csv "Yuval Harari" --category "history" --tags-csv "anthropology" \
  --status "read" --finished-at "2026-05-01" >/dev/null

# List all (newest first)
result=$(_bookshelf_ls)
assert_contains "$result" "sapiens-harari"
assert_contains "$result" "atomic-habits-clear"

# Category filter
result=$(_bookshelf_ls --category history)
assert_contains "$result" "sapiens-harari"
assert_not_contains "$result" "atomic-habits-clear"

# Shelf filter
result=$(_bookshelf_ls --shelf nightstand)
assert_contains "$result" "atomic-habits-clear"
assert_not_contains "$result" "sapiens-harari"

# Status filter (both are "read")
result=$(_bookshelf_ls --status read)
assert_contains "$result" "sapiens-harari"
assert_contains "$result" "atomic-habits-clear"

teardown_temp_repo "$tmp"
```

- [ ] **Step 2: Run — expect FAIL**

- [ ] **Step 3: Implement lib/cmd_ls.zsh**

```zsh
#!/usr/bin/env zsh
# bookshelf ls — list books, newest first (by finished_at, then created_at).

_bookshelf_ls() {
  local category="" shelf="" status="" year="" limit=50
  while (( $# )); do
    case "$1" in
      --category)   category="$2"; shift 2 ;;
      --category=*) category="${1#--category=}"; shift ;;
      --shelf)      shelf="$2"; shift 2 ;;
      --shelf=*)    shelf="${1#--shelf=}"; shift ;;
      --status)     status="$2"; shift 2 ;;
      --status=*)   status="${1#--status=}"; shift ;;
      --year)       year="$2"; shift 2 ;;
      --year=*)     year="${1#--year=}"; shift ;;
      --limit)      limit="$2"; shift 2 ;;
      --limit=*)    limit="${1#--limit=}"; shift ;;
      -*) print -r -- "ls: unknown flag $1" >&2; return 1 ;;
      *)  print -r -- "ls: unexpected arg $1" >&2; return 1 ;;
    esac
  done

  local repo
  repo=$(bookshelf_repo_path) || return 2

  local -a files
  files=("$repo"/books/*.md(N))
  if (( ${#files} == 0 )); then
    print -r -- "no books yet"
    return 0
  fi

  local f slug title cat tags shelves st finished created body_year
  local -a rows
  for f in $files; do
    [[ "${f:t}" == _categories.yml || "${f:t}" == _shelves.yml ]] && continue
    [[ "${f:t}" == _*.md ]] && continue
    slug=$(awk -F': ' '/^slug:/{print $2; exit}' "$f")
    title=$(awk -F': ' '/^title:/{gsub(/^"|"$/, "", $2); print $2; exit}' "$f")
    cat=$(awk -F': ' '/^category:/{print $2; exit}' "$f")
    shelves=$(awk -F': ' '/^shelves:/{print $2; exit}' "$f")
    st=$(awk -F': ' '/^status:/{print $2; exit}' "$f")
    finished=$(awk -F': ' '/^finished_at:/{print $2; exit}' "$f")
    created=$(awk -F': ' '/^created_at:/{print $2; exit}' "$f")
    body_year="${finished:0:4}"
    [[ -n "$category" && "$cat" != "$category" ]] && continue
    [[ -n "$status"   && "$st"  != "$status"   ]] && continue
    [[ -n "$year"     && "$body_year" != "$year" ]] && continue
    if [[ -n "$shelf" ]]; then
      [[ "$shelves" == *"$shelf"* ]] || continue
    fi
    rows+=("${finished:-${created}}	$slug	$cat	$st	$title")
  done

  if (( ${#rows} == 0 )); then
    print -r -- "no books match those filters"
    return 0
  fi

  print -rl -- $rows \
    | sort -r \
    | head -n "$limit" \
    | awk -F'\t' '{printf "%s  %-30s  [%s]  (%s)  %s\n", substr($1,1,10), $2, $3, $4, $5}'
}
```

- [ ] **Step 4: Run — expect PASS**

- [ ] **Step 5: Commit**

```bash
cd /Users/amittiwari/Projects/AmitTiwari/bookshelf
git add lib/cmd_ls.zsh tests/cli/test_ls.zsh
git commit -m "feat(cli): ls — list books with filters"
```

---

## Phase 9: cmd_show.zsh

### Task 9.1: show test + impl

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/cli/test_show.zsh`
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/lib/cmd_show.zsh`

- [ ] **Step 1: Write test**

```zsh
#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"
source "$repo_root/lib/_import_helpers.zsh"
source "$repo_root/lib/cmd_show.zsh"

tmp=$(setup_temp_repo)
export BOOKSHELF_REPO="$tmp"

bookshelf_write_record --title "Atomic Habits" --slug "atomic-habits-clear" \
  --authors-csv "James Clear" --category "craft" --tags-csv "habits" \
  --summary "Compound habits change identity." \
  --status "read" --rating "5" >/dev/null

# Exact slug
result=$(_bookshelf_show atomic-habits-clear)
assert_contains "$result" "Atomic Habits"
assert_contains "$result" "James Clear"
assert_contains "$result" "Compound habits"

# Prefix
result=$(_bookshelf_show atomic)
assert_contains "$result" "Atomic Habits"

# No match
_bookshelf_show xyz 2>/dev/null && rc=0 || rc=$?
assert_eq 1 "$rc"

teardown_temp_repo "$tmp"
```

- [ ] **Step 2: Run — expect FAIL**

- [ ] **Step 3: Implement lib/cmd_show.zsh**

```zsh
#!/usr/bin/env zsh
# bookshelf show — print one book file by slug prefix.

_bookshelf_show() {
  local prefix="$1"
  if [[ -z "$prefix" ]]; then
    print -r -- "show: slug required" >&2; return 1
  fi
  local repo
  repo=$(bookshelf_repo_path) || return 2

  local -a matches
  matches=("$repo"/books/"${prefix}"*.md(N))
  matches=("${(@)matches:#$repo/books/_*.md}")
  if (( ${#matches} == 0 )); then
    print -r -- "show: no book matches prefix '$prefix'" >&2
    return 1
  fi
  if (( ${#matches} > 1 )); then
    print -r -- "show: prefix '$prefix' matches multiple books:"
    local m
    for m in $matches; do print -r -- "  ${${m:t}:r}"; done
    return 1
  fi
  cat "${matches[1]}"
}
```

- [ ] **Step 4: Run — expect PASS**

- [ ] **Step 5: Commit**

```bash
cd /Users/amittiwari/Projects/AmitTiwari/bookshelf
git add lib/cmd_show.zsh tests/cli/test_show.zsh
git commit -m "feat(cli): show — print book by slug prefix"
```

---

## Phase 10: cmd_find.zsh

### Task 10.1: find test + impl

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/cli/test_find.zsh`
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/lib/cmd_find.zsh`

- [ ] **Step 1: Write test**

```zsh
#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"
source "$repo_root/lib/_import_helpers.zsh"
source "$repo_root/lib/cmd_find.zsh"

tmp=$(setup_temp_repo)
export BOOKSHELF_REPO="$tmp"

bookshelf_write_record --title "Atomic Habits" --slug "atomic-habits-clear" \
  --authors-csv "James Clear" --category "craft" \
  --summary "Compound habits change identity." >/dev/null
bookshelf_write_record --title "Sapiens" --slug "sapiens-harari" \
  --authors-csv "Yuval Harari" --category "history" \
  --summary "A brief history of humankind." >/dev/null

result=$(_bookshelf_find "compound")
assert_contains "$result" "atomic-habits-clear"
assert_not_contains "$result" "sapiens-harari"

result=$(_bookshelf_find "humankind")
assert_contains "$result" "sapiens-harari"

result=$(_bookshelf_find "xyzzy")
assert_contains "$result" "no matches"

teardown_temp_repo "$tmp"
```

- [ ] **Step 2: Run — expect FAIL**

- [ ] **Step 3: Implement lib/cmd_find.zsh**

```zsh
#!/usr/bin/env zsh
# bookshelf find — full-text search via rg (preferred) or grep.

_bookshelf_find() {
  if (( $# == 0 )); then
    print -r -- "find: query required" >&2; return 1
  fi
  local query="$*"
  local repo
  repo=$(bookshelf_repo_path) || return 2
  local dir="$repo/books"
  [[ -d "$dir" ]] || { print -r -- "no matches"; return 0; }

  local raw
  if (( $+commands[rg] )); then
    raw=$(rg --color=never -l -i -F -- "$query" "$dir" 2>/dev/null || true)
  else
    raw=$(grep -rl -i -F -- "$query" "$dir" 2>/dev/null || true)
  fi
  local -a hits=("${(@f)raw}")
  hits=("${(@)hits:#}")
  hits=("${(@)hits:#$repo/books/_*.md}")

  if (( ${#hits} == 0 )); then
    print -r -- "no matches for: $query"
    return 0
  fi

  local f slug cat line
  for f in $hits; do
    slug=$(awk -F': ' '/^slug:/{print $2; exit}' "$f")
    cat=$(awk -F': ' '/^category:/{print $2; exit}' "$f")
    line=$(grep -i -F -- "$query" "$f" | head -n 1 | cut -c1-120)
    print -r -- "$slug  [$cat]  $line"
  done
}
```

- [ ] **Step 4: Run — expect PASS**

- [ ] **Step 5: Commit**

```bash
cd /Users/amittiwari/Projects/AmitTiwari/bookshelf
git add lib/cmd_find.zsh tests/cli/test_find.zsh
git commit -m "feat(cli): find — full-text search via rg/grep"
```

---

## Phase 11: cmd_edit.zsh

### Task 11.1: edit test + impl

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/cli/test_edit.zsh`
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/lib/cmd_edit.zsh`

- [ ] **Step 1: Write test using a stub EDITOR**

```zsh
#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"
source "$repo_root/lib/_import_helpers.zsh"
source "$repo_root/lib/cmd_edit.zsh"

tmp=$(setup_temp_repo)
export BOOKSHELF_REPO="$tmp"

bookshelf_write_record --title "Atomic Habits" --slug "atomic-habits-clear" \
  --authors-csv "James Clear" --category "craft" --status "read" \
  --summary "Initial summary." >/dev/null
(cd "$tmp" && git add -A && git -c user.email=t@t -c user.name=t commit -q -m "seed")

# Fake editor: append a line to the body
fake_editor_script=$(mktemp)
cat > "$fake_editor_script" <<'EOS'
#!/usr/bin/env zsh
print -r -- "EDITED-MARKER" >> "$1"
EOS
chmod +x "$fake_editor_script"
export BOOKSHELF_EDITOR="$fake_editor_script"

_bookshelf_edit atomic-habits-clear

# updated_at should be bumped (file rewritten), EDITED-MARKER should be in body
content=$(cat "$tmp/books/atomic-habits-clear.md")
assert_contains "$content" "EDITED-MARKER"

# Commit landed
(cd "$tmp" && git log --oneline -1) | grep -q "edit" || { print -r -- "FAIL: edit commit not landed"; exit 1; }

rm -f "$fake_editor_script"
teardown_temp_repo "$tmp"
```

- [ ] **Step 2: Run — expect FAIL**

- [ ] **Step 3: Implement lib/cmd_edit.zsh**

```zsh
#!/usr/bin/env zsh
# bookshelf edit — open a book file in $EDITOR, bump updated_at, commit.

_bookshelf_edit() {
  local prefix=""
  while (( $# )); do
    case "$1" in
      -*) print -r -- "edit: unknown flag $1" >&2; return 1 ;;
      *)
        if [[ -z "$prefix" ]]; then prefix="$1"; shift
        else print -r -- "edit: unexpected arg $1" >&2; return 1; fi ;;
    esac
  done
  [[ -z "$prefix" ]] && { print -r -- "edit: slug required" >&2; return 1; }

  local repo
  repo=$(bookshelf_repo_path) || return 2

  local -a matches=("$repo"/books/"${prefix}"*.md(N))
  matches=("${(@)matches:#$repo/books/_*.md}")
  if (( ${#matches} == 0 )); then
    print -r -- "edit: no book matches '$prefix'" >&2; return 1
  fi
  if (( ${#matches} > 1 )); then
    print -r -- "edit: prefix matches multiple books:"
    print -rl -- ${matches:t:r}
    return 1
  fi
  local f="${matches[1]}"

  "${BOOKSHELF_EDITOR:-${EDITOR:-vi}}" "$f"

  local now
  now=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
  local tmp_out
  tmp_out=$(mktemp)
  awk -v u="$now" '
    BEGIN { in_fm = 0; updated_seen = 0 }
    /^---$/ {
      print
      if (in_fm == 1 && !updated_seen) print "updated_at: " u
      in_fm = (in_fm == 0) ? 1 : 2
      next
    }
    in_fm == 1 && /^updated_at:/ { print "updated_at: " u; updated_seen = 1; next }
    { print }
  ' "$f" > "$tmp_out"
  mv "$tmp_out" "$f"

  local slug title
  slug=$(awk -F': ' '/^slug:/{print $2; exit}' "$f")
  title=$(awk -F': ' '/^title:/{gsub(/^"|"$/, "", $2); print $2; exit}' "$f")
  (
    cd "$repo"
    git add "${f#$repo/}"
    git commit -m "book: edit ${slug} — ${title}"
  )
}
```

- [ ] **Step 4: Run — expect PASS**

- [ ] **Step 5: Commit**

```bash
cd /Users/amittiwari/Projects/AmitTiwari/bookshelf
git add lib/cmd_edit.zsh tests/cli/test_edit.zsh
git commit -m "feat(cli): edit — open in \$EDITOR, bump updated_at, commit"
```

---

## Phase 12: cmd_rm.zsh

### Task 12.1: rm test + impl

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/cli/test_rm.zsh`
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/lib/cmd_rm.zsh`

- [ ] **Step 1: Write test**

```zsh
#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"
source "$repo_root/lib/_import_helpers.zsh"
source "$repo_root/lib/cmd_rm.zsh"

tmp=$(setup_temp_repo)
export BOOKSHELF_REPO="$tmp"

bookshelf_write_record --title "Atomic Habits" --slug "atomic-habits-clear" \
  --authors-csv "James Clear" --category "craft" >/dev/null
(cd "$tmp" && git add -A && git -c user.email=t@t -c user.name=t commit -q -m seed)

_bookshelf_rm -y atomic-habits-clear

[[ -f "$tmp/books/atomic-habits-clear.md" ]] && { print -r -- "FAIL: file still exists"; exit 1; }
(cd "$tmp" && git log --oneline -1) | grep -q "remove" || { print -r -- "FAIL: remove commit not landed"; exit 1; }

teardown_temp_repo "$tmp"
```

- [ ] **Step 2: Run — expect FAIL**

- [ ] **Step 3: Implement lib/cmd_rm.zsh**

```zsh
#!/usr/bin/env zsh
# bookshelf rm — git rm a book by slug prefix, with confirm.

_bookshelf_rm() {
  local prefix="" yes=0
  while (( $# )); do
    case "$1" in
      -y|--yes) yes=1; shift ;;
      -*) print -r -- "rm: unknown flag $1" >&2; return 1 ;;
      *)
        if [[ -z "$prefix" ]]; then prefix="$1"; shift
        else print -r -- "rm: unexpected arg $1" >&2; return 1; fi ;;
    esac
  done
  [[ -z "$prefix" ]] && { print -r -- "rm: slug required" >&2; return 1; }

  local repo
  repo=$(bookshelf_repo_path) || return 2
  local -a matches=("$repo"/books/"${prefix}"*.md(N))
  matches=("${(@)matches:#$repo/books/_*.md}")
  if (( ${#matches} == 0 )); then
    print -r -- "rm: no book matches '$prefix'" >&2; return 1
  fi
  if (( ${#matches} > 1 )); then
    print -r -- "rm: prefix matches multiple books:"
    print -rl -- ${matches:t:r}
    return 1
  fi
  local f="${matches[1]}"

  local slug title
  slug=$(awk -F': ' '/^slug:/{print $2; exit}' "$f")
  title=$(awk -F': ' '/^title:/{gsub(/^"|"$/, "", $2); print $2; exit}' "$f")

  if (( ! yes )); then
    print -r -- "Remove ${slug}? — ${title}"
    print -n -- "Confirm (y/N)? "
    local reply
    read -r reply
    [[ "$reply" == [yY]* ]] || { print -r -- "cancelled"; return 0; }
  fi

  (
    cd "$repo"
    git rm -q "${f#$repo/}"
    git commit -q -m "book: remove ${slug} — ${title}"
  )
  print -r -- "removed $slug"
}
```

- [ ] **Step 4: Run — expect PASS**

- [ ] **Step 5: Commit**

```bash
cd /Users/amittiwari/Projects/AmitTiwari/bookshelf
git add lib/cmd_rm.zsh tests/cli/test_rm.zsh
git commit -m "feat(cli): rm — git rm by slug prefix, with confirm"
```

---

## Phase 13: cmd_reread.zsh

### Task 13.1: reread test + impl

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/cli/test_reread.zsh`
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/lib/cmd_reread.zsh`

- [ ] **Step 1: Write test**

```zsh
#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"
source "$repo_root/lib/_import_helpers.zsh"
source "$repo_root/lib/cmd_reread.zsh"

tmp=$(setup_temp_repo)
export BOOKSHELF_REPO="$tmp"

bookshelf_write_record --title "Atomic Habits" --slug "atomic-habits-clear" \
  --authors-csv "James Clear" --category "craft" --status "read" >/dev/null
(cd "$tmp" && git add -A && git -c user.email=t@t -c user.name=t commit -q -m seed)

# Use a fake editor that appends content under the re-read section
fake_editor_script=$(mktemp)
cat > "$fake_editor_script" <<'EOS'
#!/usr/bin/env zsh
print -r -- "Re-read notes appended." >> "$1"
EOS
chmod +x "$fake_editor_script"
export BOOKSHELF_EDITOR="$fake_editor_script"

_bookshelf_reread atomic-habits-clear

content=$(cat "$tmp/books/atomic-habits-clear.md")
assert_contains "$content" "## Re-read"
assert_contains "$content" "Re-read notes appended."
(cd "$tmp" && git log --oneline -1) | grep -q "re-read" || { print -r -- "FAIL: re-read commit not landed"; exit 1; }

rm -f "$fake_editor_script"
teardown_temp_repo "$tmp"
```

- [ ] **Step 2: Run — expect FAIL**

- [ ] **Step 3: Implement lib/cmd_reread.zsh**

```zsh
#!/usr/bin/env zsh
# bookshelf reread — append `## Re-read <year>` section, open in editor, commit.

_bookshelf_reread() {
  local prefix="$1"
  [[ -z "$prefix" ]] && { print -r -- "reread: slug required" >&2; return 1; }

  local repo
  repo=$(bookshelf_repo_path) || return 2
  local -a matches=("$repo"/books/"${prefix}"*.md(N))
  matches=("${(@)matches:#$repo/books/_*.md}")
  if (( ${#matches} == 0 )); then
    print -r -- "reread: no book matches '$prefix'" >&2; return 1
  fi
  if (( ${#matches} > 1 )); then
    print -r -- "reread: prefix matches multiple books:"
    print -rl -- ${matches:t:r}
    return 1
  fi
  local f="${matches[1]}"

  local year now
  year=$(date -u +'%Y')
  now=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

  # Append section
  {
    print -r --
    print -r -- "## Re-read $year"
    print -r --
    print -r -- "_Notes from this re-read:_"
    print -r --
  } >> "$f"

  # Bump updated_at
  local tmp_out
  tmp_out=$(mktemp)
  awk -v u="$now" '
    BEGIN { in_fm = 0; updated_seen = 0 }
    /^---$/ {
      print
      if (in_fm == 1 && !updated_seen) print "updated_at: " u
      in_fm = (in_fm == 0) ? 1 : 2
      next
    }
    in_fm == 1 && /^updated_at:/ { print "updated_at: " u; updated_seen = 1; next }
    { print }
  ' "$f" > "$tmp_out"
  mv "$tmp_out" "$f"

  "${BOOKSHELF_EDITOR:-${EDITOR:-vi}}" "$f"

  local slug title
  slug=$(awk -F': ' '/^slug:/{print $2; exit}' "$f")
  title=$(awk -F': ' '/^title:/{gsub(/^"|"$/, "", $2); print $2; exit}' "$f")
  (
    cd "$repo"
    git add "${f#$repo/}"
    git commit -m "book: re-read ${slug} ${year} — ${title}"
  )
}
```

- [ ] **Step 4: Run — expect PASS**

- [ ] **Step 5: Commit**

```bash
cd /Users/amittiwari/Projects/AmitTiwari/bookshelf
git add lib/cmd_reread.zsh tests/cli/test_reread.zsh
git commit -m "feat(cli): reread — append section, bump updated_at, commit"
```

---

## Phase 14: cmd_import_isbn.zsh

### Task 14.1: import-isbn test + impl

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/cli/test_import_isbn.zsh`
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/lib/cmd_import_isbn.zsh`
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/fixtures/openlibrary/isbn-9780735211292.json`

- [ ] **Step 1: Write ISBN fixture**

`tests/fixtures/openlibrary/isbn-9780735211292.json`:

```json
{
  "ISBN:9780735211292": {
    "title": "Atomic Habits",
    "authors": [{"name": "James Clear"}],
    "publish_date": "2018",
    "number_of_pages": 320,
    "cover": {"large": "https://covers.openlibrary.org/b/id/9259256-L.jpg"}
  }
}
```

- [ ] **Step 2: Write test**

```zsh
#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"
source "$repo_root/lib/_lookup.zsh"
source "$repo_root/lib/_import_helpers.zsh"
source "$repo_root/lib/cmd_import_isbn.zsh"

if ! (( $+commands[jq] )); then
  print -r -- "SKIP: jq not installed"
  exit 0
fi

tmp=$(setup_temp_repo)
export BOOKSHELF_REPO="$tmp"
export BOOKSHELF_LOOKUP_FIXTURES="$repo_root/tests/fixtures"

_bookshelf_import_isbn 9780735211292

[[ -f "$tmp/books/atomic-habits-clear.md" ]] || { print -r -- "FAIL: file not created"; exit 1; }
content=$(cat "$tmp/books/atomic-habits-clear.md")
assert_contains "$content" 'title: "Atomic Habits"'
assert_contains "$content" "authors: [James Clear]"
assert_contains "$content" "status: want-to-read"
assert_contains "$content" "published: false"

teardown_temp_repo "$tmp"
```

- [ ] **Step 3: Implement lib/cmd_import_isbn.zsh**

```zsh
#!/usr/bin/env zsh
# bookshelf import-isbn — seed skeletons for one or more ISBNs.

_bookshelf_isbn_lookup() {
  local isbn="$1"
  local fixtures="${BOOKSHELF_LOOKUP_FIXTURES:-}"
  if [[ -n "$fixtures" ]]; then
    local f="$fixtures/openlibrary/isbn-${isbn}.json"
    if [[ -f "$f" ]]; then cat "$f"; return 0; fi
    print -r -- "{}"
    return 0
  fi
  if ! (( $+commands[curl] )); then
    print -r -- "bookshelf: curl required for ISBN lookup" >&2
    return 4
  fi
  curl -sS --max-time 8 "https://openlibrary.org/api/books?bibkeys=ISBN:${isbn}&format=json&jscmd=data"
}

_bookshelf_import_isbn() {
  if (( $# == 0 )); then
    print -r -- "import-isbn: at least one ISBN required" >&2; return 1
  fi
  if ! (( $+commands[jq] )); then
    print -r -- "import-isbn: jq required to parse Open Library response" >&2; return 4
  fi

  local isbn
  for isbn in "$@"; do
    local payload title author cover year pages
    payload=$(_bookshelf_isbn_lookup "$isbn") || continue
    title=$(print -r -- "$payload" | jq -r --arg k "ISBN:$isbn" '.[$k].title // empty')
    if [[ -z "$title" ]]; then
      print -r -- "import-isbn: no result for $isbn — skipping" >&2
      continue
    fi
    author=$(print -r -- "$payload" | jq -r --arg k "ISBN:$isbn" '.[$k].authors[0].name // empty')
    cover=$(print -r -- "$payload" | jq -r --arg k "ISBN:$isbn" '.[$k].cover.large // empty')
    year=$(print -r -- "$payload" | jq -r --arg k "ISBN:$isbn" '.[$k].publish_date // empty' | head -c 4)
    pages=$(print -r -- "$payload" | jq -r --arg k "ISBN:$isbn" '.[$k].number_of_pages // empty')

    local author_last="${author##* }"
    local slug
    slug=$(bookshelf_slug "$title" "$author_last")

    local out
    out=$(bookshelf_write_record \
      --title "$title" --slug "$slug" \
      --authors-csv "$author" \
      --isbn13 "$isbn" \
      --published-year "$year" \
      --pages "$pages" \
      --cover-url "$cover" \
      --status "want-to-read" \
      --published "false" \
      --category "life" \
      --origin "isbn:$isbn")
    print -r -- "seeded $out"
  done
}
```

- [ ] **Step 4: Run — expect PASS**

- [ ] **Step 5: Commit**

```bash
cd /Users/amittiwari/Projects/AmitTiwari/bookshelf
git add lib/cmd_import_isbn.zsh tests/cli/test_import_isbn.zsh tests/fixtures/openlibrary/isbn-9780735211292.json
git commit -m "feat(cli): import-isbn — seed skeletons from ISBN list"
```

---

## Phase 15: cmd_wisdomify.zsh

### Task 15.1: wisdomify test + impl

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/cli/test_wisdomify.zsh`
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/lib/cmd_wisdomify.zsh`

- [ ] **Step 1: Write test**

```zsh
#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"
source "$repo_root/lib/_shared.zsh"
source "$repo_root/lib/_import_helpers.zsh"
source "$repo_root/lib/cmd_wisdomify.zsh"

tmp=$(setup_temp_repo)
export BOOKSHELF_REPO="$tmp"

bookshelf_write_record --title "Atomic Habits" --slug "atomic-habits-clear" \
  --authors-csv "James Clear" --category "craft" \
  --learnings "1. **Compound habits.** *(yours)*" \
  --passages "> Habits are compound interest. — p.18" >/dev/null

# Without wisdom CLI available: should write `## Wisdom Candidates` section
unset BOOKSHELF_WISDOM_CMD
fake_path=$(mktemp -d)
export PATH="$fake_path"  # nothing on PATH -> wisdom missing

_bookshelf_wisdomify atomic-habits-clear

content=$(cat "$tmp/books/atomic-habits-clear.md")
assert_contains "$content" "Wisdom Candidates"

teardown_temp_repo "$tmp"
rm -rf "$fake_path"
```

- [ ] **Step 2: Implement lib/cmd_wisdomify.zsh**

```zsh
#!/usr/bin/env zsh
# bookshelf wisdomify — retroactively walk a book's learnings/passages and
# promote them to wisdom. Non-interactive in this MVP: appends a
# `## Wisdom Candidates` section listing eligible items. Interactive promotion
# is invoked when running through the skill (which spawns an agent session).

_bookshelf_wisdomify() {
  local prefix="$1"
  [[ -z "$prefix" ]] && { print -r -- "wisdomify: slug required" >&2; return 1; }

  local repo
  repo=$(bookshelf_repo_path) || return 2
  local -a matches=("$repo"/books/"${prefix}"*.md(N))
  matches=("${(@)matches:#$repo/books/_*.md}")
  if (( ${#matches} == 0 )); then
    print -r -- "wisdomify: no book matches '$prefix'" >&2; return 1
  fi
  local f="${matches[1]}"

  # If `wisdom` CLI is on PATH, hand off to the agent session in the wisdom
  # repo (interactive promotion).
  local wisdom_cmd="${BOOKSHELF_WISDOM_CMD:-wisdom}"
  if (( $+commands[$wisdom_cmd] )); then
    print -r -- "wisdomify: handing off to '$wisdom_cmd' agent session — pick which learnings to promote."
    # The agent reads the book file via context and runs the wisdom-capture
    # flow per pick. Each commit lands in the wisdom repo with --book-id.
    local book_id
    book_id=$(awk -F': ' '/^id:/{print $2; exit}' "$f")
    print -r -- "Book: $f (id=$book_id)" | "$wisdom_cmd"
    return 0
  fi

  # Fallback: append a `## Wisdom Candidates` section listing learnings + passages.
  print -r -- "wisdomify: '$wisdom_cmd' CLI not on PATH — writing Wisdom Candidates section."

  local learnings passages
  learnings=$(awk '/^## Top Learnings$/{flag=1; next} /^## /{flag=0} flag' "$f")
  passages=$(awk '/^## Favorite Passages$/{flag=1; next} /^## /{flag=0} flag' "$f")

  {
    print -r --
    print -r -- "## Wisdom Candidates"
    print -r --
    print -r -- "_Items eligible for promotion to the wisdom repo. Run \`wisdom \"<text>\" --book-id <ulid>\` per pick, then append the returned ulid to \`wisdom_ids\` above._"
    print -r --
    print -r -- "### Learnings"
    print -r --
    [[ -n "$learnings" ]] && print -r -- "$learnings"
    print -r --
    print -r -- "### Passages"
    print -r --
    [[ -n "$passages" ]] && print -r -- "$passages"
  } >> "$f"

  print -r -- "wrote candidates section to $f"
}
```

- [ ] **Step 3: Run — expect PASS**

- [ ] **Step 4: Commit**

```bash
cd /Users/amittiwari/Projects/AmitTiwari/bookshelf
git add lib/cmd_wisdomify.zsh tests/cli/test_wisdomify.zsh
git commit -m "feat(cli): wisdomify — retroactive promotion w/ graceful fallback"
```

---

## Phase 16: Invariant tests (categories closed, shelves hint, push gate)

### Task 16.1: categories-closed test

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/cli/test_categories_closed.zsh`

- [ ] **Step 1: Write test**

```zsh
#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"

# Build set of allowed keys from _categories.yml
allowed=$(awk '/^  - key:/{print $3}' "$repo_root/books/_categories.yml")
[[ -n "$allowed" ]] || { print -r -- "FAIL: no categories defined"; exit 1; }

# Every book's category must appear in `allowed`
for f in "$repo_root"/books/*.md; do
  base="${f:t}"
  [[ "$base" == _*.md ]] && continue
  [[ -f "$f" ]] || continue
  cat=$(awk -F': ' '/^category:/{print $2; exit}' "$f")
  if ! print -r -- "$allowed" | grep -qx "$cat"; then
    print -r -- "FAIL: $f has invalid category '$cat'"
    exit 1
  fi
done
```

- [ ] **Step 2: Run — expect PASS (empty book corpus, vacuously true)**

### Task 16.2: shelves-hint test

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/cli/test_shelves_hint.zsh`

- [ ] **Step 1: Write test**

```zsh
#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"

# _shelves.yml must parse with a top-level `shelves:` key (array or empty list)
content=$(cat "$repo_root/books/_shelves.yml")
assert_contains "$content" "shelves:"
```

### Task 16.3: push-gate test

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/cli/test_push_gate.zsh`

- [ ] **Step 1: Write test**

```zsh
#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"

# .gitignore must list .bookshelf-session
content=$(cat "$repo_root/.gitignore")
assert_contains "$content" ".bookshelf-session"
```

- [ ] **Step 2: Run all + commit**

```bash
cd /Users/amittiwari/Projects/AmitTiwari/bookshelf
zsh tests/run.zsh
git add tests/cli/test_categories_closed.zsh tests/cli/test_shelves_hint.zsh tests/cli/test_push_gate.zsh
git commit -m "test: invariants — categories closed, shelves hint, push-gate"
```

---

## Phase 17: Skill content (.agents/skills/bookshelf-capture/)

### Task 17.1: Write SKILL.md

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/.agents/skills/bookshelf-capture/SKILL.md`

- [ ] **Step 1: Write the skill content**

```markdown
---
name: bookshelf-capture
description: Use when the user wants to log a book they've read (or want to read) to their personal bookshelf — identifies the book via Open Library / Google Books, intakes favorite passages, derives learnings (grounded from passages + the web; suggests more from priors with a hallucination guard, cap 5), categorizes into a closed bucket from books/_categories.yml, optionally promotes selected learnings/passages to the sibling wisdom repo, writes a frontmatter markdown file, and commits.
---

# Bookshelf Capture

## Overview

You are logging one book entry into the user's personal bookshelf corpus.
The corpus lives at `$BOOKSHELF_REPO` (default `~/Projects/AmitTiwari/bookshelf`).
Each book becomes one Markdown file under `books/<slug>.md` with strict
frontmatter, then one git commit.

You MUST follow the 14-step flow below in order. Do not skip steps. Do not
improvise the schema. If you cannot proceed for any reason, surface the
problem to the user explicitly — do not silently save partial data.

You MUST `cd` into the repo before any git operation: `cd "$BOOKSHELF_REPO"`
(or the value from `bookshelf_repo_path`).

## Inputs

You receive the title via one of:
- A first user-turn message containing `Log this book onto my bookshelf using the bookshelf-capture skill. Title: <title>`
- An interactive prompt where the user types `/bookshelf-capture` and then provides the title
- Inside a re-read flow (existing slug detected), the user picks `re-read | edit | view`

## The 14-step flow

### Step 1 — Detect inputs

If the first turn already has a title, use it. If `Author hint:` is on the
next line, capture it. Otherwise ask: "What's the title? (optionally include
the author, e.g. 'Atomic Habits by James Clear')".

### Step 2 — Identify the book

Call `bookshelf_lookup "<title>"` (Open Library primary; falls back to Google
Books when no match). Show the top 1–3 matches as a compact table with title,
authors, year, pages, cover thumbnail URL if present. User picks `[1] [2] [3]
none of these / search again with author / paste manual metadata`.

If `--no-network` mode (no `curl`/`jq`), fall back to manual entry: prompt
for `title`, `authors` (comma-separated), `published_year`, `pages`,
`isbn13` (optional).

Halt early if user can't confirm a match and refuses manual entry.

### Step 3 — Check existing

Compute the slug via `bookshelf_slug "<title>" "<author-last>"`. If
`bookshelf_find_by_slug "$slug"` returns a path, the book already exists.
Offer: `[edit] adjust existing | [re-read] append a Re-read section | [view]
print and exit | [cancel]`.

Also do a fuzzy match: if any existing slug has Levenshtein distance ≤ 3 from
the candidate slug, warn the user before proceeding ("Did you mean: `<slug>`?").

### Step 4 — Intake reading state

Prompt with prefilled defaults; user hits enter to accept:
- `status` (default `read`)
- `started_at` (default empty)
- `finished_at` (default today's date if status=read)
- `rating` (default empty; accept 1–5)
- `format` (default empty; physical | ebook | audio)

### Step 5 — Intake favorite passages (optional)

"Paste favorite passages — quote text + optional page. Enter alone to skip.
Type `done` to finish."

Loop: read a passage (multiline, terminated by blank line or `EOF`), prompt
for page reference, append to passage list.

### Step 6 — Derive learnings from passages

For each passage, propose 1–3 candidate learnings grounded *in that passage
only*. Show a table:

| # | Passage (snippet) | Derived learning | Keep? |

User accepts/edits/rejects each. Provenance suffix: `(from passage, p.<N>)`.

### Step 7 — Suggest learnings (optional, asks first)

Ask: "Suggest 5 more learnings from what's known about the book? [y/n]"

If yes: web-ground first (Wikipedia book article, Open Library description,
publisher summary). Only fall through to LLM priors when no grounded source
is found. Mark provenance: `(from web — wikipedia)` / `(from web —
publisher)` / `(suggested — verify)`.

**Hallucination guard:** If fewer than 2 of 5 candidate learnings rate
`high` confidence, do NOT propose anything. Say: "I don't know this book
well enough to suggest learnings. You'll need to enter them manually." Add
zero suggested learnings to the file.

Cap: 5 suggested learnings.

### Step 8 — Propose category + tags + shelves

Read `books/_categories.yml`. Pick exactly one `category` key + confidence
(`high|med|low`) + `second_best`. If no fit, propose new bucket with
`key`/`label`/`color` (from `color_pool`).

Propose 2–7 lowercase hyphenated `tags`.

Propose 0–3 `shelves`. Read `books/_shelves.yml` first; prefer existing
shelves to prevent typo splits. If proposing a new shelf, append it to
`_shelves.yml` (commit alongside the book).

Show proposal as a table. User confirms / edits.

### Step 9 — Personal notes (optional)

"Add freeform notes? Enter alone to skip."

### Step 10 — Wisdom promotion (optional)

"Promote any learnings or passages to a wisdom snippet? Reply with indices
(e.g. `2, 5`) or `none`."

For each pick:
1. Prefill snippet body with the learning text or the passage.
2. Shell out: `wisdom "<text>" --book-id <ulid>` (book ulid from Step 11
   below — for ordering reasons, generate the ulid up-front in Step 7's tail
   and pass it through).
3. Capture returned wisdom ulid from stderr/stdout (`wisdom` prints the
   final path; parse the ulid from filename).
4. Append to a local `wisdom_ids` array.

If `wisdom` CLI is missing on PATH: fall back gracefully. Append a
`## Wisdom Candidates` section to the book file body listing the picked
items, and tell the user: "Install the `wisdom` CLI to promote these. Until
then, candidates are recorded in the book file."

### Step 11 — Write file

Compute (or reuse from Step 7's tail): `id = bookshelf_ulid`.

Call `bookshelf_write_record` with every field collected. The helper renders
frontmatter + body sections deterministically. Path is `books/<slug>.md`.

### Step 12 — Commit

```bash
cd "$BOOKSHELF_REPO"
git add books/<slug>.md books/_shelves.yml  # _shelves.yml only if changed
git commit -m "book: <category> — <title> by <author-last>

learnings: <N>
passages: <M>
wisdom_promoted: <space-separated ulids>"
```

Re-read commit subject: `book: re-read <slug> <year> — <title> by <author-last>`.

### Step 13 — Push (per session)

Read `.bookshelf-session` if present. Honor `always` / `never`. Otherwise
prompt: `[y]es | [n]o | [a]lways | [n]ever`. Persist to `.bookshelf-session`
(gitignored).

If `git push origin main` is denied with a direct-push-to-main policy
message: create topic branch `book/<slug-prefix>`, reset local main to
`origin/main`, push branch, open PR with `gh pr create`. Report PR URL.

### Step 14 — Report + loop

Print: file path, category, tags, shelves, commit sha, wisdom_ids if any, PR
URL if push happened.

## Edge cases

### Existing slug

Step 3 catches this. The re-read branch:
1. Read existing file. Show summary (title, author, finished_at, rating,
   categories, learnings count).
2. Ask the user how to proceed.
3. **re-read** → append `## Re-read <year>` section, loop steps 4–10 with
   the new content, bump `updated_at`. Category is frozen (don't re-ask).
4. **edit** → jump to Step 4 with existing values prefilled.
5. **view** → print full file and exit.

### Skeleton entries

If the user identifies the book but skips passages + learnings + notes
entirely, write the skeleton with `status: want-to-read` + `published:
false`. Use case: capturing a reading list.

### Hallucination guard fires

Step 7 sees < 2 high-confidence candidates → suggest nothing. Continue with
whatever passage-derived learnings the user has (which may be zero).

### No categories.yml

If `books/_categories.yml` is missing or unparseable, halt with error. Do
not invent buckets.

## Verification before declaring done

- File written under `books/<slug>.md`
- Frontmatter parses as valid YAML (run `awk '/^---$/{n++;next}{if(n==1)print}' books/<slug>.md` and pipe to a YAML parser if available)
- `id` matches a ULID pattern (26 chars, Crockford base32)
- `slug` matches filename
- Commit landed on local `main` (or topic branch in fallback case)
- If wisdoms were promoted: each ulid appears both in the book's
  `wisdom_ids` array and as a file in the wisdom repo

See REFERENCE.md for prompt templates, the JSON output schema for Step 8,
and the wisdom-promotion fallback rendering.
```

### Task 17.2: Write REFERENCE.md

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/.agents/skills/bookshelf-capture/REFERENCE.md`

- [ ] **Step 1: Write reference**

```markdown
# Bookshelf Capture — Reference

## Categorization output schema (Step 8)

```json
{
  "primary": "<key from books/_categories.yml>",
  "confidence": "high | med | low",
  "tags": ["string", "string"],
  "shelves": ["string"],
  "reason": "<one sentence>",
  "new_bucket_proposal": null | {
    "key": "<snake_case>",
    "label": "<Human Readable>",
    "color": "<one of color_pool unused>",
    "reason": "<why existing buckets don't fit>"
  },
  "second_best": "<key from _categories.yml different from primary>"
}
```

## Frontmatter rendering rules

- YAML scalars: quote `title`, `subtitle`, `who_should_read` with double
  quotes always (titles often contain `:`).
- `created_at` / `updated_at` / `started_at` / `finished_at`: ISO 8601 with
  `Z` suffix for full timestamps; date-only for the started/finished pair
  is acceptable (`2026-05-01`).
- `tags`, `shelves`, `authors`, `wisdom_ids`: inline flow style —
  `tags: [a, b, c]` — not block style. Empty arrays render as `[]`.
- Null values: literal `null` (no quotes).
- `isbn13`: quoted string (preserves leading zeros, treats as opaque).
- `rating`: integer 1–5 or `null`.
- `pages` / `published_year`: integer or `null`.

## Commit message body limits

Subject: max 72 chars after `book: <category> — ` prefix. Truncate title
with `…` (U+2026) if needed.

Body lines:
```
learnings: <N>
passages: <M>
wisdom_promoted: <ulid1> <ulid2> …
```

Omit lines where the value is zero / empty.

## Push policy state

`.bookshelf-session` is a single line, one of: `y` | `n` | `always` |
`never`. Gitignored. Absence = "ask".

## Suggested learning provenance tags

| Source | Tag suffix on the learning |
|---|---|
| User-provided passage | `*(from passage, p.<N>)*` |
| Wikipedia book article | `*(from web — wikipedia)*` |
| Open Library description | `*(from web — openlibrary)*` |
| Publisher / author site | `*(from web — publisher)*` |
| LLM priors (low-priority backfill) | `*(suggested — verify)*` |
| User-typed inline | `*(yours)*` |

## Wisdom promotion fallback

If `wisdom` CLI is missing on PATH, append this to the book file body
before Step 12 (instead of cross-repo shell-out):

```markdown
## Wisdom Candidates

_Items eligible for promotion to the wisdom repo. Run `wisdom "<text>" --book-id <ulid>` per pick, then append the returned ulid to `wisdom_ids` above._

### Learnings
<copy each picked learning>

### Passages
<copy each picked passage>
```

## Engine-specific notes

- **Claude:** The Skill tool loads this file directly. You see this content
  as in-session instruction.
- **Codex:** Read at session start via AGENTS.md or the `$bookshelf-capture`
  prefix trigger. Codex may not surface YAML files; in that case the user
  pastes the title, and Codex follows the same flow from instruction.
- **Devin:** Triggered via `/bookshelf-capture`. Devin's tool surface
  includes file write + shell, which is all this flow needs.
```

### Task 17.3: Write skill README

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/.agents/skills/bookshelf-capture/README.md`

- [ ] **Step 1: Write README**

```markdown
# bookshelf-capture

Personal skill for logging books to the [bookshelf](https://github.com/AmitTiwari/bookshelf) corpus.

Install via the at-skills catalog:

```bash
cd path/to/your/bookshelf-repo
npx skills@latest add amit-t/skills --skill bookshelf-capture
```

After install, trigger in-session:

- Claude Code: `/bookshelf-capture` (or describe the task)
- Devin: `/bookshelf-capture`
- Codex: `$bookshelf-capture`

Or from terminal:

```bash
bookshelf "Atomic Habits" --author "James Clear"
```

See `SKILL.md` for the full 14-step capture flow and `REFERENCE.md` for
schemas and provenance tags.
```

### Task 17.4: Skill-fixtures test

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/tests/skill/test_skill_fixtures.zsh`

- [ ] **Step 1: Write the test**

```zsh
#!/usr/bin/env zsh
set -e
script_path=${0:A}
repo_root=${script_path:h:h:h}
source "$repo_root/tests/_assert.zsh"

# SKILL.md must have YAML frontmatter with name + description
skill="$repo_root/.agents/skills/bookshelf-capture/SKILL.md"
assert_file_exists "$skill"
fm=$(awk '/^---$/{n++; next} n==1{print}' "$skill")
assert_contains "$fm" "name: bookshelf-capture"
assert_contains "$fm" "description:"

# REFERENCE.md must exist
assert_file_exists "$repo_root/.agents/skills/bookshelf-capture/REFERENCE.md"

# Skill mentions every required step
content=$(cat "$skill")
for step in "Step 1" "Step 2" "Step 3" "Step 4" "Step 5" "Step 6" "Step 7" "Step 8" "Step 9" "Step 10" "Step 11" "Step 12" "Step 13" "Step 14"; do
  assert_contains "$content" "$step"
done

# Skill references the closed taxonomy + the wisdom hand-off + the fallback
assert_contains "$content" "books/_categories.yml"
assert_contains "$content" "wisdom"
assert_contains "$content" "Wisdom Candidates"
```

- [ ] **Step 2: Run + commit**

```bash
cd /Users/amittiwari/Projects/AmitTiwari/bookshelf
zsh tests/run.zsh
git add .agents/skills/bookshelf-capture/ tests/skill/test_skill_fixtures.zsh
git commit -m "feat(skill): bookshelf-capture SKILL.md + REFERENCE.md + README.md"
```

---

## Phase 18: install.sh

### Task 18.1: Write install.sh

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/install.sh`

- [ ] **Step 1: Write installer**

```zsh
#!/usr/bin/env zsh
# Bookshelf installer: symlinks bin/bookshelf into ~/bin. Idempotent.
#
# The bookshelf-capture skill is NOT installed by this script. It is published
# in the at-skills catalog and installed per-project via the `skills` CLI:
#
#   npx skills@latest add amit-t/skills --skill bookshelf-capture

set -e
script_path=${0:A}
repo_root=${script_path:h}

mkdir -p "$HOME/bin"

link_or_replace() {
  local src="$1" dst="$2"
  mkdir -p "${dst:h}"
  if [[ -L "$dst" ]]; then
    rm -f "$dst"
  elif [[ -e "$dst" ]]; then
    print -r -- "install: $dst exists and is not a symlink; skipping" >&2
    return 0
  fi
  ln -s "$src" "$dst"
  print -r -- "  linked $dst -> $src"
}

print -r -- "Installing bookshelf CLI from: $repo_root"
link_or_replace "$repo_root/bin/bookshelf" "$HOME/bin/bookshelf"

print
print -r -- "Add these lines to your ~/.zshrc (or equivalent):"
print -r -- ""
print -r -- "    export PATH=\"\$HOME/bin:\$PATH\""
print -r -- "    export BOOKSHELF_REPO=\"$repo_root\""
print -r -- ""
print -r -- "Install the bookshelf-capture skill into this project:"
print -r -- ""
print -r -- "    cd $repo_root"
print -r -- "    npx skills@latest add amit-t/skills --skill bookshelf-capture"
print -r -- ""
print -r -- "Done. Try: bookshelf --help"
```

- [ ] **Step 2: Make executable + commit**

```bash
chmod +x /Users/amittiwari/Projects/AmitTiwari/bookshelf/install.sh
cd /Users/amittiwari/Projects/AmitTiwari/bookshelf
git add install.sh
git commit -m "feat: install.sh — symlink bin/bookshelf into ~/bin"
```

---

## Phase 19: Docs

### Task 19.1: ARCHITECTURE.md

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/docs/ARCHITECTURE.md`

- [ ] **Step 1: Write architecture doc**

```markdown
# Architecture

## Data model

One Markdown file per book entry. Storage path: `books/<slug>.md`.

Slug rules: lowercase ASCII transliteration of the title (subtitle stripped
after `:` / `—` / ` - `), leading article (`The`/`A`/`An`) removed,
non-alphanum collapsed to hyphens, capped at 80 chars, then `-<author-last>`
appended. Series get `-N` suffix (e.g. `foundation-1-asimov.md`). Collisions
resolve by appending `-<published_year>`.

Frontmatter (YAML) carries all metadata; body below the fence is structured
sections: `## Summary`, `## Top Learnings`, `## Favorite Passages`,
`## Notes`, optional `## Re-read <year>`, optional `## Wisdom Candidates`
(graceful fallback when `wisdom` CLI is missing).

### Frontmatter schema

| Field | Type | Notes |
|---|---|---|
| `id` | string (ulid) | 26-char lowercase Crockford base32 |
| `slug` | string | matches filename |
| `title` | string | quoted |
| `subtitle` | string | quoted, often empty |
| `authors` | array of strings | inline flow style |
| `isbn13` | string \| null | quoted (leading-zero safe) |
| `published_year` | int \| null | |
| `pages` | int \| null | |
| `language` | string | ISO 639-1 (default `en`) |
| `cover_url` | string \| null | quoted; absolute URL |
| `goodreads_url` | string \| null | |
| `amazon_url` | string \| null | |
| `format` | string \| null | physical \| ebook \| audio |
| `genre` | string \| null | one string |
| `status` | string | read \| reading \| abandoned \| want-to-read |
| `started_at` | string \| null | date (YYYY-MM-DD) |
| `finished_at` | string \| null | date |
| `rating` | int \| null | 1–5 |
| `category` | string | one key from `_categories.yml` |
| `tags` | array of strings | lowercase, hyphenated |
| `shelves` | array of strings | open hint file in `_shelves.yml` |
| `recommended_by` | string \| null | |
| `who_should_read` | string | quoted; may be empty |
| `published` | bool | defaults true if status=read, else false |
| `created_at` | string | ISO 8601 UTC |
| `updated_at` | string | ISO 8601 UTC |
| `import_origin` | string | manual \| isbn:<n> \| goodreads:<id> \| url:<u> |
| `wisdom_ids` | array of strings | ulids of wisdom snippets spawned from this book |

## Components

```
bin/bookshelf            # thin zsh dispatcher
└── lib/
    ├── _shared.zsh           # ulid, slug, repo path, length guard
    ├── _lookup.zsh           # Open Library + Google Books (fixture-replayable)
    ├── _import_helpers.zsh   # bookshelf_write_record
    └── cmd_*.zsh             # one module per subcommand

.agents/skills/bookshelf-capture/
├── SKILL.md     # 14-step capture flow
├── REFERENCE.md # schemas, provenance tags, fallback rendering
└── README.md    # installation pointer

books/
├── _categories.yml  # closed taxonomy + color_pool
├── _shelves.yml     # open hint file
├── _example.md      # template fixture
└── <slug>.md        # the corpus
```

## Capture flow

```
bookshelf "<title>" [--author "..."]            terminal
   │
   ├── parse args; length guard
   ├── launch claude / codex / devin             engine
   │     └── /bookshelf-capture (auto-engages via AGENTS.md description)
   │           └── SKILL.md 14-step flow
   │                 ├── identify via Open Library / Google Books
   │                 ├── check existing slug (re-read / edit / view branch)
   │                 ├── intake status / dates / rating / format
   │                 ├── intake passages
   │                 ├── derive learnings from passages
   │                 ├── suggest learnings (web-grounded; hallucination guard)
   │                 ├── propose category + tags + shelves
   │                 ├── optional wisdom promotion (cross-repo CLI call)
   │                 ├── write books/<slug>.md
   │                 ├── git add + commit
   │                 └── prompt push?
   └── exit
```

## Wisdom integration

Bookshelf shells out to `wisdom "<text>" --book-id <ulid>` for each
learning/passage the user picks during Step 10 of the capture flow.

- Wisdom commits land in `~/Projects/AmitTiwari/wisdom` (separate repo,
  per-snippet commits).
- Book commit lands last with `wisdom_ids: [<ulid1>, <ulid2>, ...]`
  populated.
- Wisdom frontmatter gains an optional `book_id` field pointing back to the
  spawning book's id (hidden in UI when null).
- Reverse query: `grep -l "book_id: $book_id" ~/Projects/AmitTiwari/wisdom/wisdoms`
  surfaces every wisdom from a given book.

If `wisdom` CLI is missing on PATH: bookshelf appends a `## Wisdom
Candidates` section to the book file and prompts the user to install +
import later.

## External tool dependencies

All optional except `git` and `zsh`. Each tool's absence produces a graceful
skip or actionable error.

| Tool | Used by | Install (macOS) |
|---|---|---|
| `git` | every commit | comes with Xcode CLT |
| `curl` | Open Library / Google Books lookups | system |
| `jq` | normalized lookup output, ISBN parsing | `brew install jq` |
| `iconv` | unicode-to-ASCII slug transliteration | system |
| `ripgrep` (`rg`) | `find` (falls back to `grep`) | `brew install ripgrep` |
| `gdate` | sub-second ULID precision (falls back to date) | `brew install coreutils` |
| `wisdom` CLI | optional wisdom promotion (graceful fallback) | sibling repo |
| `claude` / `codex` / `devin` | capture session | per-vendor |

## Trade-offs + non-goals

- **No backend.** The site builds statically from the submodule.
- **Closed taxonomy for categories.** New buckets land only via the skill's
  explicit "propose new bucket" path, gated on user confirmation.
- **One commit per book entry (or per re-read).** Chosen for blame +
  revertability.
- **Mutable book files.** Books are documents, not atoms — unlike wisdom
  snippets, they accumulate edits over time. No body_hash field (git is
  authoritative for content integrity).
- **No real-time sync.** Entries land on local main first; push is opt-in
  per session.
```

### Task 19.2: USAGE.md

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/docs/USAGE.md`

- [ ] **Step 1: Write usage doc**

```markdown
# Usage

## Capture

```bash
bookshelf                                  # launch agent; skill prompts for title
bookshelf "Atomic Habits"                  # title prefilled
bookshelf "Atomic Habits" --author "James Clear"
bookshelf -                                # title from stdin
bookshelf -e                               # open $EDITOR with a template
bookshelf --engine codex "Sapiens"         # override engine
```

Environment overrides:
- `BOOKSHELF_REPO` (default `~/Projects/AmitTiwari/bookshelf`)
- `BOOKSHELF_ENGINE` (`claude` | `codex` | `devin`)
- `BOOKSHELF_EDITOR` (overrides `$EDITOR`)
- `BOOKSHELF_NO_PUSH` (skip push prompts)

## Browse

```bash
bookshelf ls                               # all books, newest first
bookshelf ls --category craft              # filter by category
bookshelf ls --shelf nightstand            # filter by shelf
bookshelf ls --status reading              # filter by status
bookshelf ls --year 2026                   # filter by finished_at year
bookshelf ls --limit 10
bookshelf show atomic                      # print one book by slug prefix
bookshelf find "compound interest"         # full-text search
```

## Edit / remove / re-read

```bash
bookshelf edit atomic-habits-clear         # open in $EDITOR, bump updated_at, commit
bookshelf rm atomic-habits-clear           # git rm with confirm
bookshelf rm -y atomic-habits-clear        # skip confirm
bookshelf reread atomic-habits-clear       # append ## Re-read <year>, edit, commit
```

## Bulk seeding

```bash
bookshelf import-isbn 9780735211292        # one ISBN
bookshelf import-isbn 9780735211292 9780062316097 9780374533557
```

Each ISBN becomes a skeleton with `status: want-to-read`, `published:
false`. Run `bookshelf reread <slug>` (or open the agent session) when you
finish reading.

## Wisdom promotion

```bash
bookshelf wisdomify atomic-habits-clear    # retroactive promotion flow
```

Hands off to the `wisdom` CLI if installed; otherwise appends a `## Wisdom
Candidates` section to the book file.

## Exit codes

- `0` success
- `1` usage / arg error
- `2` repo path resolution failure
- `3` engine CLI not on PATH
- `4` required tool missing (`curl`, `jq`)
- `6` length-guard violation (title too short/long)
```

### Task 19.3: INSTALL.md

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/docs/INSTALL.md`

- [ ] **Step 1: Write install doc**

```markdown
# Install

## CLI

```bash
git clone <this-repo> ~/Projects/AmitTiwari/bookshelf
cd ~/Projects/AmitTiwari/bookshelf
./install.sh
```

Then add to `~/.zshrc` (the installer prints these lines too):

```zsh
export PATH="$HOME/bin:$PATH"
export BOOKSHELF_REPO="$HOME/Projects/AmitTiwari/bookshelf"
```

Reload: `source ~/.zshrc` (or open a new terminal).

Verify: `bookshelf --help`.

## Skill

The `bookshelf-capture` skill is published in the at-skills catalog. Install
per-project:

```bash
cd ~/Projects/AmitTiwari/bookshelf
npx skills@latest add amit-t/skills --skill bookshelf-capture
```

After install, the skill auto-engages on:

- Claude Code: `/bookshelf-capture` slash command, or any prompt mentioning
  "log a book", "add to bookshelf", etc.
- Devin: `/bookshelf-capture`
- Codex: `$bookshelf-capture` prefix

To upgrade: re-run the `npx` command.

## Optional dependencies

- `jq` for normalized lookup output and ISBN parsing: `brew install jq`
- `ripgrep` for fast `find`: `brew install ripgrep`
- `coreutils` for sub-second-precision ULIDs: `brew install coreutils`

The `wisdom` CLI is required only if you want to promote book learnings
into the wisdom corpus during capture (Step 10 of the skill flow). Without
it, candidates are recorded in the book file under `## Wisdom Candidates`
for later import.

## Publishing the skill (maintainer-only)

The `bookshelf-capture` skill lives in `.agents/skills/bookshelf-capture/`
in this repo as the authoritative source. To publish to the at-skills
catalog (`amit-t/skills`):

1. Copy `.agents/skills/bookshelf-capture/` into the `amit-t/skills` repo
   under `bookshelf-capture/`.
2. Update `amit-t/skills/index.json` to register the skill name + version.
3. Commit + push from `amit-t/skills`.

The `npx skills@latest add amit-t/skills --skill bookshelf-capture` command
pulls from `main` of that repo.
```

- [ ] **Step 2: Commit docs**

```bash
cd /Users/amittiwari/Projects/AmitTiwari/bookshelf
git add docs/ARCHITECTURE.md docs/USAGE.md docs/INSTALL.md
git commit -m "docs: ARCHITECTURE, USAGE, INSTALL"
```

---

## Phase 20: CI workflows

### Task 20.1: ci.yml

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/.github/workflows/ci.yml`

- [ ] **Step 1: Write CI workflow**

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]

jobs:
  shell-tests:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install zsh deps
        run: brew install jq ripgrep
      - name: Run test suite
        run: zsh tests/run.zsh
```

### Task 20.2: trigger-amittiwari-me.yml

**Files:**
- Create: `/Users/amittiwari/Projects/AmitTiwari/bookshelf/.github/workflows/trigger-amittiwari-me.yml`

- [ ] **Step 1: Write redeploy workflow**

```yaml
name: Trigger amittiwari.me redeploy

# When a book is captured and pushed here, ask DigitalOcean App Platform to
# rebuild amittiwari.me so the new entry surfaces under /bookshelf. The site
# consumes this repo as a git submodule (external/bookshelf) and pulls
# --remote on each build, so a redeploy is all that's needed.
#
# One-time setup:
# 1. Create a DigitalOcean Personal Access Token at
#    https://cloud.digitalocean.com/account/api/tokens with the `apps:read`
#    and `apps:write` scopes.
# 2. Find the App ID for amittiwari.me from the DO console
#    (https://cloud.digitalocean.com/apps/<uuid>) or `doctl apps list`.
# 3. This repo → Settings → Secrets and variables → Actions → add both:
#      - DO_API_TOKEN
#      - DO_APP_ID
#
# Missing either secret turns the workflow into a no-op with a warning, so
# pushes are never blocked.

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions: {}

concurrency:
  group: trigger-amittiwari-me-bookshelf
  cancel-in-progress: false

jobs:
  redeploy:
    runs-on: ubuntu-latest
    steps:
      - name: Request deployment via DigitalOcean API
        env:
          DO_API_TOKEN: ${{ secrets.DO_API_TOKEN }}
          DO_APP_ID: ${{ secrets.DO_APP_ID }}
        run: |
          set -euo pipefail
          if [ -z "${DO_API_TOKEN:-}" ] || [ -z "${DO_APP_ID:-}" ]; then
            echo "::warning::DO_API_TOKEN / DO_APP_ID secrets not set on this repo. Skipping redeploy."
            exit 0
          fi
          response=$(mktemp)
          status=$(curl -sS -o "$response" -w "%{http_code}" \
            -X POST \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer ${DO_API_TOKEN}" \
            -d '{"force_build": true}' \
            "https://api.digitalocean.com/v2/apps/${DO_APP_ID}/deployments")
          echo "DO API returned HTTP $status"
          head -c 4000 "$response" || true
          echo
          if [ "$status" -lt 200 ] || [ "$status" -ge 300 ]; then
            echo "::error::DigitalOcean deployment request failed (HTTP $status)"
            exit 1
          fi
```

- [ ] **Step 2: Commit workflows**

```bash
cd /Users/amittiwari/Projects/AmitTiwari/bookshelf
git add .github/workflows/ci.yml .github/workflows/trigger-amittiwari-me.yml
git commit -m "ci: shell-tests workflow + amittiwari.me redeploy trigger"
```

---

## Phase 21: Wisdom-side book_id field

### Task 21.1: Patch wisdom `_import_helpers.zsh`

**Files:**
- Modify: `/Users/amittiwari/Projects/AmitTiwari/wisdom/lib/_import_helpers.zsh`

- [ ] **Step 1: Add `book_id` plumbing**

Add a `--book-id` parser arm + an optional frontmatter field. Patch the
function signature to accept `book_id` and emit the line right after
`import_origin`. The site treats `book_id: null` as "hide from UI".

Replace the function body in `lib/_import_helpers.zsh` (entire file rewrite,
since the current version is short):

```zsh
# Helpers shared across import formats.

wisdom_write_record() {
  local body="$1" source_url="$2" source_author="$3" note="$4" \
        category="$5" tags_csv="$6" origin="$7" book_id="${8:-}"
  [[ -z "$category" ]] && category="life"
  local repo id now year month dir tags_yaml
  repo=$(wisdom_repo_path) || return 2
  id=$(wisdom_ulid)
  now=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
  year=${now:0:4}
  month=${now:5:2}
  dir="$repo/wisdoms/$year/$month"
  mkdir -p "$dir"

  if [[ -z "$tags_csv" ]]; then
    tags_yaml='[]'
  else
    tags_yaml="[${tags_csv// , /, }]"
    tags_yaml="${tags_yaml// ,/,}"
  fi

  local hash
  hash=$(wisdom_body_hash "$body")

  local out="$dir/$id.md"
  {
    print -r -- "---"
    print -r -- "id: $id"
    print -r -- "created_at: $now"
    print -r -- "body_hash: $hash"
    print -r -- "category: $category"
    print -r -- "tags: $tags_yaml"
    print -r -- "source_url: ${source_url:-null}"
    print -r -- "source_author: ${source_author:-null}"
    print -r -- "note: \"${note}\""
    print -r -- "import_origin: ${origin:-manual}"
    print -r -- "book_id: ${book_id:-null}"
    print -r -- "---"
    print -r --
    print -r -- "$body"
  } > "$out"

  print -r -- "$out"
}
```

### Task 21.2: Patch wisdom `cmd_capture.zsh`

**Files:**
- Modify: `/Users/amittiwari/Projects/AmitTiwari/wisdom/lib/cmd_capture.zsh:63-110`

- [ ] **Step 1: Add `--book-id` flag parsing**

After the existing `case` block inside `_wisdom_capture`'s arg loop, add a
`--book-id` arm. The captured value should be exported as
`WISDOM_BOOK_ID_HINT` so the skill (which runs in the agent session) can
read it and pass it down to `wisdom_write_record`.

Open `lib/cmd_capture.zsh` and edit the arg-parse loop. Find the line:

```
      *)
        # Positional snippet (joined by spaces if multiple)
```

Insert above it:

```
      --book-id)
        export WISDOM_BOOK_ID_HINT="$2"; shift 2 ;;
      --book-id=*)
        export WISDOM_BOOK_ID_HINT="${1#--book-id=}"; shift ;;
```

### Task 21.3: Patch wisdom skill SKILL.md

**Files:**
- Modify: `/Users/amittiwari/Projects/AmitTiwari/wisdom/.agents/skills/wisdom-capture/SKILL.md`

- [ ] **Step 1: Document book_id**

At the end of "### URL import handoff" section, add a new subsection:

```markdown
### Cross-repo invocation from bookshelf

When invoked with `WISDOM_BOOK_ID_HINT` set in the environment (the bookshelf
skill's wisdom-promotion path sets this before shelling out to `wisdom`),
pass that value through to `wisdom_write_record`'s 8th positional argument
(`book_id`). The resulting wisdom frontmatter carries `book_id: <ulid>`,
enabling the reverse query "show all wisdom from this book".

If `WISDOM_BOOK_ID_HINT` is unset or empty, render `book_id: null`.
```

### Task 21.4: Patch wisdom ARCHITECTURE.md

**Files:**
- Modify: `/Users/amittiwari/Projects/AmitTiwari/wisdom/docs/ARCHITECTURE.md:12-23`

- [ ] **Step 1: Add `book_id` row to schema table**

Find the schema table that ends with `| import_origin | string \| null | one of \`manual\`, \`file:<basename>\`, \`url:<url>\`, \`notion:<basename>\` |` and append directly below it:

```markdown
| `book_id` | string (ulid) \| null | optional back-pointer to a bookshelf book entry; rendered as `null` when not set |
```

### Task 21.5: Run wisdom tests + commit

- [ ] **Step 1: Run wisdom test suite**

```bash
cd /Users/amittiwari/Projects/AmitTiwari/wisdom
zsh tests/run.zsh
```

Expected: existing tests still pass (book_id is additive).

- [ ] **Step 2: Commit wisdom changes**

```bash
cd /Users/amittiwari/Projects/AmitTiwari/wisdom
git add lib/_import_helpers.zsh lib/cmd_capture.zsh .agents/skills/wisdom-capture/SKILL.md docs/ARCHITECTURE.md
git commit -m "feat: optional book_id cross-link for bookshelf integration"
```

---

## Phase 22: amittiwari-me bridge

### Task 22.1: Add bookshelf as submodule

**Files:**
- Modify: `/Users/amittiwari/Projects/AmitTiwari/amittiwari-me/.gitmodules`

- [ ] **Step 1: Add submodule**

Push the local bookshelf repo to its remote first (if not already), then:

```bash
cd /Users/amittiwari/Projects/AmitTiwari/amittiwari-me
git submodule add ../bookshelf external/bookshelf
git submodule update --init --remote external/bookshelf
```

(Use the actual remote URL once the bookshelf repo is pushed to GitHub.
For local-only development, the relative-path `../bookshelf` works.)

### Task 22.2: Extend Book type

**Files:**
- Modify: `/Users/amittiwari/Projects/AmitTiwari/amittiwari-me/src/lib/types.ts:16-29`

- [ ] **Step 1: Replace the Book interface**

```typescript
export interface Book {
  slug: string;
  title: string;
  author: string;            // joined from authors[] for back-compat
  authors?: string[];
  subtitle?: string;
  coverImage: string;
  dateRead: string;
  rating: number;
  category: string[];
  tags: string[];
  shelves?: string[];
  excerpt: string;
  takeaways: string;
  amazonLink?: string;
  goodreadsUrl?: string;
  publishedYear?: number;
  pages?: number;
  format?: string;
  genre?: string;
  status?: 'read' | 'reading' | 'abandoned' | 'want-to-read';
  startedAt?: string;
  finishedAt?: string;
  recommendedBy?: string;
  whoShouldRead?: string;
  wisdomIds?: string[];
  published: boolean;
}
```

### Task 22.3: Update books.ts to read from submodule with bridge

**Files:**
- Modify: `/Users/amittiwari/Projects/AmitTiwari/amittiwari-me/src/lib/books.ts`

- [ ] **Step 1: Rewrite books.ts**

```typescript
import { format } from 'date-fns';
import fs from 'fs';
import matter from 'gray-matter';
import path from 'path';
import { isContentPublished } from './publishing';
import type { Book } from './types';

const legacyBooksDirectory = path.join(process.cwd(), 'src/content/books');
const submoduleBooksDirectory = path.join(process.cwd(), 'external/bookshelf/books');

function readDir(dir: string): string[] {
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir).filter((n) => (n.endsWith('.md') || n.endsWith('.mdx')) && !n.startsWith('_'));
}

function extractSummary(content: string): { excerpt: string; takeaways: string } {
  // Pull the first paragraph after `## Summary` into excerpt; strip section from takeaways.
  const summaryMatch = content.match(/^## Summary\s*\n+([\s\S]*?)(?=\n## |\Z)/m);
  if (!summaryMatch) return { excerpt: '', takeaways: content };
  const excerpt = summaryMatch[1].trim().split('\n\n')[0];
  const takeaways = content.replace(/^## Summary\s*\n+[\s\S]*?(?=\n## |\Z)/m, '').trim();
  return { excerpt, takeaways };
}

function bridgeRichToFlat(slug: string, fileContents: string, isRich: boolean): Book {
  const { data, content } = matter(fileContents);

  // Date formatting
  let formattedDate = '';
  const rawDate = data.dateRead ?? data.finished_at ?? data.finishedAt;
  if (rawDate) {
    try {
      formattedDate = format(new Date(rawDate), 'MMMM yyyy');
    } catch {
      formattedDate = String(rawDate);
    }
  }

  // Authors mapping
  const authors: string[] = Array.isArray(data.authors)
    ? data.authors
    : data.author
      ? [data.author]
      : [];
  const author = authors.join(' & ') || data.author || '';

  // Category mapping (rich = single string, flat = array)
  const categoryRaw = data.category;
  const category: string[] = Array.isArray(categoryRaw) ? categoryRaw : categoryRaw ? [categoryRaw] : [];

  // Tags + shelves
  const tags: string[] = Array.isArray(data.tags) ? data.tags : [];
  const shelves: string[] | undefined = Array.isArray(data.shelves) ? data.shelves : undefined;

  // Cover image
  const coverImage: string = data.cover_url ?? data.coverImage ?? '';

  // Summary extraction (rich files split body into sections; flat files don't)
  let excerpt: string;
  let takeaways: string;
  if (isRich) {
    const split = extractSummary(content);
    excerpt = data.excerpt ?? split.excerpt;
    takeaways = split.takeaways || content;
  } else {
    excerpt = data.excerpt ?? '';
    takeaways = content;
  }

  const frontmatterPublished = data.published !== undefined ? data.published : undefined;
  const publishingTags = [...tags, ...category];

  return {
    slug,
    title: data.title || '',
    author,
    authors,
    subtitle: data.subtitle || undefined,
    coverImage,
    dateRead: formattedDate,
    rating: typeof data.rating === 'number' ? data.rating : 0,
    category,
    tags,
    shelves,
    excerpt,
    takeaways,
    amazonLink: data.amazon_url ?? data.amazonLink,
    goodreadsUrl: data.goodreads_url ?? undefined,
    publishedYear: data.published_year ?? undefined,
    pages: data.pages ?? undefined,
    format: data.format ?? undefined,
    genre: data.genre ?? undefined,
    status: data.status ?? undefined,
    startedAt: data.started_at ?? undefined,
    finishedAt: data.finished_at ?? undefined,
    recommendedBy: data.recommended_by ?? undefined,
    whoShouldRead: data.who_should_read ?? undefined,
    wisdomIds: Array.isArray(data.wisdom_ids) ? data.wisdom_ids : undefined,
    published: isContentPublished('books', slug, frontmatterPublished, publishingTags),
  };
}

function readBookFile(filePath: string, isRich: boolean): Book | null {
  const fileName = path.basename(filePath);
  const slug = fileName.replace(/\.(md|mdx)$/, '');
  const fileContents = fs.readFileSync(filePath, 'utf8');
  return bridgeRichToFlat(slug, fileContents, isRich);
}

export async function getAllBooks(): Promise<Book[]> {
  const richFiles = readDir(submoduleBooksDirectory).map((n) => ({
    path: path.join(submoduleBooksDirectory, n),
    isRich: true,
  }));
  const legacyFiles = readDir(legacyBooksDirectory).map((n) => ({
    path: path.join(legacyBooksDirectory, n),
    isRich: false,
  }));

  // Rich files win on slug collision (bookshelf is source of truth)
  const seen = new Set<string>();
  const all: Book[] = [];
  for (const { path: p, isRich } of [...richFiles, ...legacyFiles]) {
    const slug = path.basename(p).replace(/\.(md|mdx)$/, '');
    if (seen.has(slug)) continue;
    seen.add(slug);
    const b = readBookFile(p, isRich);
    if (b && b.published) all.push(b);
  }

  return all.sort((a, b) => {
    if (a.dateRead && b.dateRead) {
      return new Date(b.dateRead).getTime() - new Date(a.dateRead).getTime();
    }
    return 0;
  });
}

export async function getBookBySlug(slug: string): Promise<Book | null> {
  for (const dir of [submoduleBooksDirectory, legacyBooksDirectory]) {
    for (const ext of ['.md', '.mdx']) {
      const p = path.join(dir, `${slug}${ext}`);
      if (fs.existsSync(p)) {
        const isRich = dir === submoduleBooksDirectory;
        return readBookFile(p, isRich);
      }
    }
  }
  return null;
}
```

### Task 22.4: Verify amittiwari-me build

- [ ] **Step 1: Build the site to confirm no type errors**

```bash
cd /Users/amittiwari/Projects/AmitTiwari/amittiwari-me
npm run build 2>&1 | tail -40
```

Expected: clean build (no TypeScript errors, no runtime errors during static
generation). The legacy three books still render; new submodule books render
when populated.

### Task 22.5: Commit amittiwari-me changes

- [ ] **Step 1: Commit**

```bash
cd /Users/amittiwari/Projects/AmitTiwari/amittiwari-me
git add .gitmodules external/bookshelf src/lib/books.ts src/lib/types.ts
git commit -m "feat(bookshelf): submodule + bridge rich frontmatter to Book type"
```

---

## Phase 23: Final wire-up + verification

### Task 23.1: Full test pass

- [ ] **Step 1: Run all bookshelf tests**

```bash
cd /Users/amittiwari/Projects/AmitTiwari/bookshelf
zsh tests/run.zsh
```

Expected: all ~18 tests pass (or skip if `jq` missing).

- [ ] **Step 2: Run all wisdom tests (verify the optional book_id field didn't break anything)**

```bash
cd /Users/amittiwari/Projects/AmitTiwari/wisdom
zsh tests/run.zsh
```

Expected: existing tests still pass.

### Task 23.2: End-to-end smoke test

- [ ] **Step 1: Manually drive the CLI**

```bash
cd /Users/amittiwari/Projects/AmitTiwari/bookshelf
./install.sh   # symlink to ~/bin
export PATH="$HOME/bin:$PATH"
export BOOKSHELF_REPO="$PWD"

bookshelf --version
bookshelf --help
bookshelf ls    # expect "no books yet"
```

Expected: help prints, ls returns "no books yet".

- [ ] **Step 2: Test ISBN seed end-to-end (requires network + jq)**

```bash
bookshelf import-isbn 9780735211292
bookshelf ls
bookshelf show atomic
```

Expected: file created, ls shows it, show prints frontmatter + body.

- [ ] **Step 3: Clean up smoke-test artifact (do not commit it)**

```bash
git status
git checkout -- books/   # discard the seeded file
```

### Task 23.3: Push topic branch + open PR (per AGENTS.md push policy)

- [ ] **Step 1: Push bookshelf changes**

If direct push to main is blocked (will be the policy for this repo):

```bash
cd /Users/amittiwari/Projects/AmitTiwari/bookshelf
git push origin main || true   # likely denied
git checkout -b feat/bootstrap
git push -u origin feat/bootstrap
gh pr create --title "feat: bootstrap bookshelf corpus + CLI + skill" \
  --body "$(cat <<'EOF'
## Summary

Bootstraps the bookshelf repo as the single-source corpus + zsh CLI + agent skill, mirroring the wisdom repo topology. See `docs/superpowers/plans/2026-05-15-bookshelf-bootstrap.md` for the full plan.

## Test plan

- [x] `zsh tests/run.zsh` — all tests pass
- [x] `bookshelf --help` works
- [x] `bookshelf import-isbn` seeds skeletons (fixture-replayable)
- [x] `bookshelf ls` / `show` / `find` work against a seeded corpus
- [x] `bookshelf edit` / `rm` / `reread` commit cleanly
- [x] `wisdomify` falls back to `## Wisdom Candidates` section when wisdom CLI missing
- [x] Skill content parses + references all 14 steps
- [x] CI workflow runs the test suite on PR
- [x] Wisdom repo gains optional `book_id` field (additive, non-breaking)
- [x] amittiwari-me bridges rich frontmatter to its existing Book type

EOF
)"
git checkout main
git reset --hard origin/main
```

- [ ] **Step 2: Push wisdom changes (same fallback)**

```bash
cd /Users/amittiwari/Projects/AmitTiwari/wisdom
git push origin main || true
git checkout -b feat/book-id-crosslink
git push -u origin feat/book-id-crosslink
gh pr create --title "feat: optional book_id cross-link for bookshelf" \
  --body "Adds optional book_id frontmatter field + --book-id CLI flag. Non-breaking (renders null when unset). Enables reverse query 'show all wisdom from a book'."
git checkout main
git reset --hard origin/main
```

- [ ] **Step 3: Push amittiwari-me changes**

```bash
cd /Users/amittiwari/Projects/AmitTiwari/amittiwari-me
git push origin main || true
git checkout -b feat/bookshelf-submodule
git push -u origin feat/bookshelf-submodule
gh pr create --title "feat(bookshelf): submodule + bridge rich frontmatter to Book type" \
  --body "Mounts bookshelf as submodule at external/bookshelf. Extends Book type with optional rich fields. Bridges rich → flat in src/lib/books.ts. Legacy src/content/books/ entries still render; submodule wins on slug collision."
git checkout main
git reset --hard origin/main
```

### Task 23.4: Final report

- [ ] **Step 1: Print summary**

Print to user:
- Bookshelf PR URL
- Wisdom PR URL
- amittiwari-me PR URL
- Test counts (e.g. `18 passed, 0 failed`)
- Next-step pointers: publish the skill to `amit-t/skills`, seed a first
  real book, set `DO_API_TOKEN` + `DO_APP_ID` secrets on the bookshelf
  repo for auto-redeploy.

---

## Self-review checklist (do this before declaring complete)

1. **Spec coverage:**
   - [x] Book-centric storage (Q1)
   - [x] Flat `books/<slug>.md` with author-suffixed slug (Q2)
   - [x] Rich frontmatter schema (Q3)
   - [x] 11 closed categories + confidence reporting (Q4)
   - [x] Identify-first capture flow with Open Library/Google Books (Q5)
   - [x] Hybrid C+D learning suggestions with hallucination guard (Q6)
   - [x] Cross-repo wisdom invocation with graceful fallback (Q7)
   - [x] No body_hash, mutable book files, anchor links on future site (Q8)
   - [x] CLI: ls / show / find / edit / rm / reread / import-isbn / wisdomify (Q9)
   - [x] Full mirror of wisdom infrastructure (Q10)
   - [x] 14-step SKILL flow + re-read branch (Q11)
   - [x] Env vars, install, push policy, commit format, license, tests, CI (Q12)
   - [x] amittiwari.me bridge approach (Q13)
   - [x] All Q14 loose ends covered (status↔published mapping, skeletons, slug rules, fuzzy match warning, ULID, fixture-based lookup tests, .gitignore, hint files, .bookshelf-session, example seed)

2. **Placeholder scan:** No TBD/TODO/`add appropriate error handling` left. All test bodies show actual zsh; all impl bodies show actual zsh; commit messages are explicit.

3. **Type consistency:**
   - `bookshelf_ulid` / `bookshelf_slug` / `bookshelf_repo_path` / `bookshelf_check_title` / `bookshelf_find_by_slug` defined in `_shared.zsh`, used in cmd files
   - `bookshelf_write_record` defined in `_import_helpers.zsh`, used in `cmd_import_isbn.zsh` + skill flow
   - `bookshelf_lookup` / `_openlibrary` / `_googlebooks` defined in `_lookup.zsh`, used in skill + tests
   - `_bookshelf_capture` / `_ls` / `_show` / `_find` / `_edit` / `_rm` / `_reread` / `_import_isbn` / `_wisdomify` all defined and routed by `bin/bookshelf` `main()`
   - `setup_temp_repo` / `teardown_temp_repo` defined in `tests/_assert.zsh`, used in every cmd test
   - Wisdom's `wisdom_write_record` 8th positional arg matches the new `--book-id` flag plumbing in `cmd_capture.zsh`
   - amittiwari-me `Book` type's optional fields match every frontmatter field bookshelf writes
