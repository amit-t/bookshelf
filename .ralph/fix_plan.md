# Ralph Fix Plan — Bookshelf Bootstrap

> **Source of truth for every task:** `docs/superpowers/plans/2026-05-15-bookshelf-bootstrap.md`
> Each item below references a specific Phase / Task in that plan. Read that
> section first — it contains the failing test, the code to write, the exact
> commands to run, and the commit message to use. Do NOT improvise content
> when the plan already specifies it.
>
> **Rules for every loop:**
> 1. Pick the highest-priority unchecked item. If High Priority has unchecked
>    items, work there first — items inside one priority bucket may have
>    intra-bucket order (numbered).
> 2. Implement using TDD: write the failing test first, run it to confirm
>    failure, write the minimal impl, run it to confirm pass, then commit.
> 3. Use the commit message specified in the plan task.
> 4. After the commit lands, tick the checkbox in this file and add a one-line
>    note under "Notes" only if you learned something the plan didn't say.
> 5. Never delete or rename `.ralph/`, `.ralphrc`, or
>    `docs/superpowers/plans/2026-05-15-bookshelf-bootstrap.md`.
> 6. If a task is blocked (missing dep, conflicting state, unclear spec),
>    stop and set `STATUS: BLOCKED` with the reason — do not invent a fix.

## Devin worker command reference

This workspace is scoped to **only** the `bookshelf` repo. Sibling repos
(`wisdom`, `amittiwari-me`) are NOT cloned — anything that touches them is
in the Deferred section at the bottom of this file; do not pick from it.

| Operation | Command |
|---|---|
| Run full test suite | `zsh tests/run.zsh` |
| Run one test file | `zsh tests/cli/test_<name>.zsh` |
| Run installer (symlinks `bin/bookshelf`) | `./install.sh` |
| Smoke help | `bin/bookshelf --help` |
| Smoke list | `BOOKSHELF_REPO="$PWD" bin/bookshelf ls` |
| Open PR (final phase) | `gh pr create --title "..." --body "..."` |

Required system tools available in the sandbox: `git`, `zsh`, `curl`, `jq`,
`ripgrep`, `gh`. If any are missing, install via `brew install <tool>` (macOS
runner) or `apt-get install -y <tool>` (Linux runner) before failing the
task.

Push policy: direct push to `main` is policy-blocked. Use the topic-branch
fallback per `AGENTS.md` — create `book/<slug-prefix>` (or `feat/<slug>` for
non-book commits), push that, open the PR. Ralph auto-PR is enabled
(`PR_ENABLED=true`); honor it.

## High Priority — Foundation (sequential; must land in order)

### Phase 0 — Repo init verification
- [ ] **0.1** Verify clean git state and main branch — see plan Phase 0 Task 0.1.

### Phase 1 — Bootstrap files (one commit per the plan: `chore: bootstrap bookshelf corpus`)
- [x] **1.1** Write `LICENSE` (dual MIT + CC BY 4.0) — plan Phase 1 Task 1.1.
- [x] **1.2** Write `README.md` — plan Phase 1 Task 1.2.
- [x] **1.3** Write `AGENTS.md` — plan Phase 1 Task 1.3.
- [x] **1.4** Write `CLAUDE.md` — plan Phase 1 Task 1.4.
- [ ] **1.5** Write `.gitignore` — plan Phase 1 Task 1.5.
- [ ] **1.6** Commit Phase 1 bundle (include the plan file itself in this commit) — plan Phase 1 Task 1.6.

### Phase 2 — Corpus scaffolding
- [ ] **2.1** Write `books/_categories.yml` (11 closed categories) — plan Phase 2 Task 2.1.
- [ ] **2.2** Write `books/_shelves.yml` (open hint file, initially empty) — plan Phase 2 Task 2.2.
- [x] **2.3** Write `books/_example.md` template fixture — plan Phase 2 Task 2.3.
- [ ] **2.4** Commit Phase 2 (`feat: closed category taxonomy + open shelves hint file + template`) — plan Phase 2 Task 2.4.

### Phase 3 — Test harness
- [ ] **3.1** Write `tests/_assert.zsh` (assertions + `setup_temp_repo` / `teardown_temp_repo`) — plan Phase 3 Task 3.1.
- [ ] **3.2** Write `tests/run.zsh`, make executable, smoke-test on empty test dir, commit (`test: harness — runner + assertions + temp-repo helpers`) — plan Phase 3 Task 3.2.

### Phase 4 — `lib/_shared.zsh` (TDD)
- [ ] **4.1** ULID test + impl — plan Phase 4 Task 4.1.
- [ ] **4.2** Slug test — plan Phase 4 Task 4.2.
- [ ] **4.3** Repo-resolve test — plan Phase 4 Task 4.3.
- [ ] **4.4** Length-guard test — plan Phase 4 Task 4.4.
- [ ] **4.5** Run all tests so far, commit (`feat(lib): _shared.zsh — ulid, slug, repo path, length guard`) — plan Phase 4 Task 4.5.

### Phase 5 — `lib/_lookup.zsh` (TDD with HTTP fixtures)
- [ ] **5.1** Write three fixture files (`tests/fixtures/openlibrary/atomic-habits.json`, `no-match.json`, `tests/fixtures/googlebooks/atomic-habits.json`) — plan Phase 5 Task 5.1.
- [ ] **5.2** Open Library lookup test + `lib/_lookup.zsh` impl — plan Phase 5 Task 5.2.
- [ ] **5.3** Google Books fallback test — plan Phase 5 Task 5.3.
- [ ] **5.4** Commit (`feat(lib): _lookup.zsh — open library + google books with fixture replay`) — plan Phase 5 Task 5.4.

### Phase 6 — `lib/_import_helpers.zsh` (TDD)
- [ ] **6.1** `bookshelf_write_record` test + impl + commit (`feat(lib): _import_helpers.zsh — bookshelf_write_record`) — plan Phase 6 Task 6.1.

### Phase 7 — `bin/bookshelf` dispatcher + capture launcher (TDD)
- [ ] **7.1** Capture test + `lib/cmd_capture.zsh` + `bin/bookshelf` + chmod + commit (`feat(cli): bookshelf dispatcher + capture command`) — plan Phase 7 Task 7.1.

## Medium Priority — Parallelizable commands, skill content, docs, CI

> Items 8.x through 16.x and 17.x through 20.x have **no inter-dependencies**
> within their bucket once Phase 7 has landed. Ralph workers running in
> parallel can claim any unchecked item from this section. Each task is
> self-contained: test file + impl file + commit.

### Phase 8 — `cmd_ls.zsh`
- [ ] **8.1** Test + impl + commit (`feat(cli): ls — list books with filters`) — plan Phase 8 Task 8.1.

### Phase 9 — `cmd_show.zsh`
- [ ] **9.1** Test + impl + commit (`feat(cli): show — print book by slug prefix`) — plan Phase 9 Task 9.1.

### Phase 10 — `cmd_find.zsh`
- [ ] **10.1** Test + impl + commit (`feat(cli): find — full-text search via rg/grep`) — plan Phase 10 Task 10.1.

### Phase 11 — `cmd_edit.zsh`
- [ ] **11.1** Test + impl + commit (`feat(cli): edit — open in $EDITOR, bump updated_at, commit`) — plan Phase 11 Task 11.1.

### Phase 12 — `cmd_rm.zsh`
- [ ] **12.1** Test + impl + commit (`feat(cli): rm — git rm by slug prefix, with confirm`) — plan Phase 12 Task 12.1.

### Phase 13 — `cmd_reread.zsh`
- [ ] **13.1** Test + impl + commit (`feat(cli): reread — append section, bump updated_at, commit`) — plan Phase 13 Task 13.1.

### Phase 14 — `cmd_import_isbn.zsh`
- [ ] **14.1** ISBN fixture + test + impl + commit (`feat(cli): import-isbn — seed skeletons from ISBN list`) — plan Phase 14 Task 14.1.

### Phase 15 — `cmd_wisdomify.zsh`
- [ ] **15.1** Test + impl + commit (`feat(cli): wisdomify — retroactive promotion w/ graceful fallback`) — plan Phase 15 Task 15.1.

### Phase 16 — Invariant tests
- [ ] **16.1** Categories-closed test — plan Phase 16 Task 16.1.
- [ ] **16.2** Shelves-hint test — plan Phase 16 Task 16.2.
- [ ] **16.3** Push-gate test, run all + commit (`test: invariants — categories closed, shelves hint, push-gate`) — plan Phase 16 Task 16.3.

### Phase 17 — Skill content (`.agents/skills/bookshelf-capture/`)
- [ ] **17.1** Write `SKILL.md` (14-step flow + re-read branch + edge cases) — plan Phase 17 Task 17.1.
- [ ] **17.2** Write `REFERENCE.md` (schemas, provenance tags, fallback rendering) — plan Phase 17 Task 17.2.
- [ ] **17.3** Write skill `README.md` — plan Phase 17 Task 17.3.
- [ ] **17.4** Skill-fixtures test + run all + commit (`feat(skill): bookshelf-capture SKILL.md + REFERENCE.md + README.md`) — plan Phase 17 Task 17.4.

### Phase 18 — `install.sh`
- [ ] **18.1** Write installer, chmod, commit (`feat: install.sh — symlink bin/bookshelf into ~/bin`) — plan Phase 18 Task 18.1.

### Phase 19 — Docs
- [ ] **19.1** Write `docs/ARCHITECTURE.md` — plan Phase 19 Task 19.1.
- [ ] **19.2** Write `docs/USAGE.md` — plan Phase 19 Task 19.2.
- [ ] **19.3** Write `docs/INSTALL.md`, commit (`docs: ARCHITECTURE, USAGE, INSTALL`) — plan Phase 19 Task 19.3.

### Phase 20 — CI workflows
- [ ] **20.1** `.github/workflows/ci.yml` — plan Phase 20 Task 20.1.
- [ ] **20.2** `.github/workflows/trigger-amittiwari-me.yml`, commit (`ci: shell-tests workflow + amittiwari.me redeploy trigger`) — plan Phase 20 Task 20.2.

## Low Priority — Bookshelf-scoped wire-up (final loop tasks)

> Only items inside this Low Priority bucket are in scope for the Devin
> bookshelf workspace. Cross-repo integration (phases 21, 22, and the
> wisdom/amittiwari-me halves of phase 23) is in the **Deferred** section at
> the bottom — it requires write access to sibling repos and is handled
> outside the Devin loop.

### Phase 23 — Final wire-up + verification (bookshelf-only slice)
- [ ] **23.1a** Run all bookshelf tests (`zsh tests/run.zsh`) — must report `*** passed, 0 failed`. Plan Phase 23 Task 23.1 (bookshelf half only).
- [ ] **23.2** End-to-end smoke test (`./install.sh`, `bookshelf --help`, `bookshelf ls`, `bookshelf import-isbn 9780735211292` with `BOOKSHELF_LOOKUP_FIXTURES` pointing at `tests/fixtures` for offline determinism, `bookshelf show atomic`, `git checkout -- books/` to discard the smoke artifact). Plan Phase 23 Task 23.2.
- [ ] **23.3a** Open the bookshelf PR per `AGENTS.md` push-policy fallback (topic branch `feat/bootstrap`, reset main, push, `gh pr create`). Plan Phase 23 Task 23.3 step 1. Report PR URL in the loop output.

## Completed
- [x] Project enabled for Ralph
- [x] Brainstorm + design grilled (deep depth, 14 questions resolved)
- [x] Implementation plan written to `docs/superpowers/plans/2026-05-15-bookshelf-bootstrap.md`
- [x] Ralph fix_plan.md authored

## Deferred — local execution required (DO NOT pick from Devin loop)

> These tasks live in sibling repositories that are not part of this Devin
> workspace. Devin workers must skip them. Amit runs them locally after the
> bookshelf loop completes and the bookshelf PR merges.

### Phase 21 — Wisdom-side `book_id` field (runs in `~/Projects/AmitTiwari/wisdom`)
- [ ] **21.1** Patch `lib/_import_helpers.zsh` — plan Phase 21 Task 21.1.
- [ ] **21.2** Patch `lib/cmd_capture.zsh` — plan Phase 21 Task 21.2.
- [ ] **21.3** Patch `.agents/skills/wisdom-capture/SKILL.md` — plan Phase 21 Task 21.3.
- [ ] **21.4** Patch `docs/ARCHITECTURE.md` — plan Phase 21 Task 21.4.
- [ ] **21.5** Run wisdom tests + commit (`feat: optional book_id cross-link for bookshelf integration`) — plan Phase 21 Task 21.5.

### Phase 22 — amittiwari-me bridge (runs in `~/Projects/AmitTiwari/amittiwari-me`)
- [ ] **22.1** Add bookshelf as submodule at `external/bookshelf` — plan Phase 22 Task 22.1.
- [ ] **22.2** Extend `Book` interface in `src/lib/types.ts` — plan Phase 22 Task 22.2.
- [ ] **22.3** Rewrite `src/lib/books.ts` with submodule + bridge logic — plan Phase 22 Task 22.3.
- [ ] **22.4** Verify `npm run build` is clean — plan Phase 22 Task 22.4.
- [ ] **22.5** Commit (`feat(bookshelf): submodule + bridge rich frontmatter to Book type`) — plan Phase 22 Task 22.5.

### Phase 23 — Final wire-up (cross-repo slice)
- [ ] **23.1b** Run all wisdom tests in the wisdom workspace — plan Phase 23 Task 23.1 (wisdom half).
- [ ] **23.3b** Open the wisdom PR (`feat/book-id-crosslink` branch) — plan Phase 23 Task 23.3 step 2.
- [ ] **23.3c** Open the amittiwari-me PR (`feat/bookshelf-submodule` branch) — plan Phase 23 Task 23.3 step 3.
- [ ] **23.4** Print final summary (all three PR URLs, combined test counts, next-step pointers including: publish skill to `amit-t/skills` catalog, seed first real book, set `DO_API_TOKEN` + `DO_APP_ID` secrets on the bookshelf repo) — plan Phase 23 Task 23.4.

## Notes
- The detailed plan is the source of truth for **every** task. Do not
  paraphrase code from memory — copy from the plan verbatim.
- TDD is mandatory for `lib/` and `cmd_*` work: failing test → impl → pass.
- Skill content (Phase 17) is text-only; no TDD beyond the
  `test_skill_fixtures.zsh` invariant check.
- `wisdomify` (Phase 15) gracefully degrades when `wisdom` CLI is missing —
  this is correct behavior, not a bug to fix.
- Hallucination guard in skill Step 7 is load-bearing: if < 2 of 5
  suggestions hit `high` confidence, propose nothing.
- Tests that hit network (`_lookup.zsh`) MUST use the
  `BOOKSHELF_LOOKUP_FIXTURES` env override pointing at `tests/fixtures` for
  determinism. Never let CI / Devin hit the live Open Library / Google Books
  APIs.
