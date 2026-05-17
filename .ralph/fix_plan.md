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
- [x] **0.1** Verify clean git state and main branch — see plan Phase 0 Task 0.1.

### Phase 1 — Bootstrap files (one commit per the plan: `chore: bootstrap bookshelf corpus`)
- [x] **1.1** Write `LICENSE` (dual MIT + CC BY 4.0) — plan Phase 1 Task 1.1.
- [x] **1.2** Write `README.md` — plan Phase 1 Task 1.2.
- [x] **1.3** Write `AGENTS.md` — plan Phase 1 Task 1.3.
- [x] **1.4** Write `CLAUDE.md` — plan Phase 1 Task 1.4.
- [x] **1.5** Write `.gitignore` — plan Phase 1 Task 1.5.
- [x] **1.6** Commit Phase 1 bundle (include the plan file itself in this commit) — plan Phase 1 Task 1.6.

### Phase 2 — Corpus scaffolding
- [x] **2.1** Write `books/_categories.yml` (11 closed categories) — plan Phase 2 Task 2.1.
- [x] **2.2** Write `books/_shelves.yml` (open hint file, initially empty) — plan Phase 2 Task 2.2.
- [x] **2.3** Write `books/_example.md` template fixture — plan Phase 2 Task 2.3.
- [x] **2.4** Commit Phase 2 (`feat: closed category taxonomy + open shelves hint file + template`) — plan Phase 2 Task 2.4.

### Phase 3 — Test harness
- [x] **3.1** Write `tests/_assert.zsh` (assertions + `setup_temp_repo` / `teardown_temp_repo`) — plan Phase 3 Task 3.1.
- [x] **3.2** Write `tests/run.zsh`, make executable, smoke-test on empty test dir, commit (`test: harness — runner + assertions + temp-repo helpers`) — plan Phase 3 Task 3.2.

### Phase 4 — `lib/_shared.zsh` (TDD)
- [x] **4.1** ULID test + impl — plan Phase 4 Task 4.1.
- [x] **4.2** Slug test — plan Phase 4 Task 4.2.
- [x] **4.3** Repo-resolve test — plan Phase 4 Task 4.3.
- [x] **4.4** Length-guard test — plan Phase 4 Task 4.4.
- [x] **4.5** Run all tests so far, commit (`feat(lib): _shared.zsh — ulid, slug, repo path, length guard`) — plan Phase 4 Task 4.5.

### Phase 5 — `lib/_lookup.zsh` (TDD with HTTP fixtures)
- [x] **5.1** Write three fixture files (`tests/fixtures/openlibrary/atomic-habits.json`, `no-match.json`, `tests/fixtures/googlebooks/atomic-habits.json`) — plan Phase 5 Task 5.1.
- [x] **5.2** Open Library lookup test + `lib/_lookup.zsh` impl — plan Phase 5 Task 5.2.
- [x] **5.3** Google Books fallback test — plan Phase 5 Task 5.3.
- [x] **5.4** Commit (`feat(lib): _lookup.zsh — open library + google books with fixture replay`) — plan Phase 5 Task 5.4.

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
- Task 5.4 under parallel-worktree orchestration: this is the plan-named
  bundle marker for Phase 5 (`feat(lib): _lookup.zsh — open library + google
  books with fixture replay`). The actual files (`lib/_lookup.zsh`,
  `tests/cli/test_lookup_openlibrary.zsh`,
  `tests/cli/test_lookup_google_fallback.zsh`, `tests/fixtures/`) ship via
  the per-task PRs from sibling branches 5.1 / 5.2 / 5.3, mirroring the
  Phase 4.5 marker pattern (commit 3873243). Verification: borrowed
  `lib/_shared.zsh` from `origin/ralph-devin/4-2-...`, `tests/_assert.zsh`
  from `origin/ralph-devin/3-1-...`, `tests/run.zsh` from
  `origin/ralph-devin/3-2-...`, `tests/fixtures/` from
  `origin/ralph-devin/5-1-...`, `lib/_lookup.zsh` +
  `tests/cli/test_lookup_openlibrary.zsh` from `origin/ralph-devin/5-2-...`,
  and `tests/cli/test_lookup_google_fallback.zsh` from
  `origin/ralph-devin/5-3-...` into the working tree, ran `zsh tests/run.zsh`
  (`2 passed, 0 failed, 0 skipped` — both lookup tests green together), then
  `git rm --cached` + `rm -rf` the borrowed files (unstaging them from the
  index since `git checkout origin/<br> -- <path>` stages them by default)
  before committing so this PR ships only the fix_plan tick (matching the
  Phase 1.6 / 2.4 / 4.5 marker pattern).
- Task 5.3 under parallel-worktree orchestration: the plan bundles every
  Phase 5 sub-task into one commit at Task 5.4 (`feat(lib): _lookup.zsh —
  open library + google books with fixture replay`) covering
  `lib/_lookup.zsh tests/cli/test_lookup_openlibrary.zsh
  tests/cli/test_lookup_google_fallback.zsh tests/fixtures/`. For per-task
  PR isolation, this worker ships ONLY
  `tests/cli/test_lookup_google_fallback.zsh` (verbatim from the plan's
  Step 1 block, including the `jq`-not-installed SKIP guard). The
  `lib/_lookup.zsh` impl + `tests/fixtures/` JSON arrive via the merged
  5.1 + 5.2 PRs; the bundle commit message at 5.4 then serves as the named
  bundle marker with no further file changes. Verification: borrowed
  `tests/_assert.zsh` from `origin/ralph-devin/3-1-...`, `tests/run.zsh`
  from `origin/ralph-devin/3-2-...`, `lib/_shared.zsh` from
  `origin/ralph-devin/4-2-...` (canonical with the macOS-iconv hardening),
  `tests/fixtures/` from `origin/ralph-devin/5-1-...`, and `lib/_lookup.zsh`
  from `origin/ralph-devin/5-2-...` into the working tree, ran
  `zsh tests/cli/test_lookup_google_fallback.zsh` (exit 0) and
  `zsh tests/run.zsh` (`1 passed, 0 failed, 0 skipped`), then `git rm
  --cached` + `rm` on the borrowed files (including unstaging them from the
  index since `git checkout origin/<br> -- <path>` stages them by default)
  before committing so this PR ships only the 5.3 artifact. The combined
  `bookshelf_lookup` short-circuits on the Open Library hit for `"Atomic
  Habits"` (slug `atomic-habits` → OL fixture has `numFound > 0` →
  normalized output carries `"source": "openlibrary"` + title `"Atomic
  Habits"`); on `"Zzz No Match"` (slug `zzz-no-match`) OL falls through to
  the `no-match.json` fixture (`numFound: 0`) and GB falls through to the
  in-helper `{"totalItems": 0, "items": []}` default, hitting the final
  `'{"source": "none"}'` branch so the assertion that the output contains
  `"source"` still passes.
- Task 5.2 under parallel-worktree orchestration: the plan bundles every
  Phase 5 sub-task into one commit at Task 5.4 (`feat(lib): _lookup.zsh —
  open library + google books with fixture replay`) covering
  `lib/_lookup.zsh tests/cli/test_lookup_openlibrary.zsh
  tests/cli/test_lookup_google_fallback.zsh tests/fixtures/`. For per-task
  PR isolation, this worker ships ONLY `lib/_lookup.zsh` (the full file
  per-plan, since it contains the OL helper plus its `googlebooks`/
  combined-`lookup` siblings used by 5.3) and
  `tests/cli/test_lookup_openlibrary.zsh`, mirroring the per-task split
  used in Phases 3/4. The 5.3 worker adds the google-fallback test only;
  the bundle commit message at 5.4 then serves as the named bundle marker
  with no further file changes. Verification: borrowed `tests/_assert.zsh`
  from `origin/ralph-devin/3-1-...`, `tests/run.zsh` from
  `origin/ralph-devin/3-2-...`, `lib/_shared.zsh` from
  `origin/ralph-devin/4-2-...` (canonical with the macOS-iconv hardening),
  and `tests/fixtures/` from `origin/ralph-devin/5-1-...` into the working
  tree, ran `zsh tests/cli/test_lookup_openlibrary.zsh` (exit 0) and
  `zsh tests/run.zsh` (`1 passed, 0 failed, 0 skipped`), then removed the
  borrowed files (including unstaging them from the index since `git
  checkout origin/<br> -- <path>` stages them by default) before
  committing so this PR ships only the 5.2 artifacts. The
  `bookshelf_lookup_openlibrary` fixture-replay path returns the OL
  `atomic-habits.json` content verbatim for the title-hit case, and falls
  through to the `no-match.json` fixture for the `"Zzz No Match Zzz"`
  slug-miss case (which slugifies to `zzz-no-match-zzz` and does not
  exist on disk).
- Task 5.1 under parallel-worktree orchestration: the plan bundles every
  Phase 5 sub-task into one commit at Task 5.4 (`feat(lib): _lookup.zsh —
  open library + google books with fixture replay`) covering
  `lib/_lookup.zsh tests/cli/test_lookup_openlibrary.zsh
  tests/cli/test_lookup_google_fallback.zsh tests/fixtures/`. For per-task
  PR isolation, this worker ships ONLY the three fixture files
  (`tests/fixtures/openlibrary/atomic-habits.json`, `no-match.json`,
  `tests/fixtures/googlebooks/atomic-habits.json`) under the commit
  `test(fixtures): openlibrary + googlebooks lookup fixtures (Task 5.1)`,
  mirroring the split pattern used in Phases 1/2/3/4. Subsequent
  5.2/5.3 workers add the lookup test files + `lib/_lookup.zsh`; the
  bundle commit message at 5.4 then serves as the named bundle marker
  with no further file changes. Verification: all three JSON files
  validate with `jq` (no parse errors); `numFound`/`docs` shape
  matches the Open Library `/search.json` response surface and
  `totalItems`/`items.volumeInfo` matches the Google Books
  `/volumes` response surface as consumed by `bookshelf_lookup_*` in
  the plan's Step 3 `lib/_lookup.zsh` body — no harness was needed
  since 5.1 ships zero zsh code.
- Task 4.4 under parallel-worktree orchestration: the plan prescribes only
  the test file `tests/cli/test_length_guard.zsh`, sourcing the
  `bookshelf_check_title` helper landed by Task 4.1 (Task 4.2's canonical
  `lib/_shared.zsh` includes it unchanged from the 4.1 baseline). This
  worker ships ONLY `tests/cli/test_length_guard.zsh`; the `_shared.zsh`
  body arrives via the 4.1/4.2 PR merges. Verification: borrowed
  `lib/_shared.zsh` from `origin/ralph-devin/4-2-...` (canonical with the
  macOS-iconv hardening), `tests/_assert.zsh` from
  `origin/ralph-devin/3-1-...`, and `tests/run.zsh` from
  `origin/ralph-devin/3-2-...` into the working tree, ran
  `zsh tests/run.zsh` (`1 passed, 0 failed, 0 skipped`) and
  `zsh tests/cli/test_length_guard.zsh` directly (exit 0), then removed the
  borrowed files before committing so this PR ships only the 4.4 test
  artifact. The three test assertions exercise: (a) below-min title `"A"`
  (1 char < min 2) returns exit code 6, (b) within-bounds `"Atomic Habits"`
  returns 0, (c) over-max 501-char title returns exit code 6.
- Task 4.3 under parallel-worktree orchestration: the plan prescribes only
  the test file `tests/cli/test_repo_resolve.zsh`, sourcing
  `bookshelf_repo_path` landed by Task 4.1 (and patched by Task 4.2 for the
  macOS-iconv exit-code issue, which is the canonical version per 4.2's
  note). This worker ships ONLY `tests/cli/test_repo_resolve.zsh`; the
  `_shared.zsh` body arrives via the 4.1/4.2 PR merges. Verification:
  borrowed `lib/_shared.zsh` from `origin/ralph-devin/4-2-...` (canonical),
  `tests/_assert.zsh` from `origin/ralph-devin/3-1-...`, and `tests/run.zsh`
  from `origin/ralph-devin/3-2-...` into the working tree, ran
  `zsh tests/run.zsh` (`1 passed, 0 failed, 0 skipped`) and
  `zsh tests/cli/test_repo_resolve.zsh` directly (exit 0), then removed the
  borrowed files before committing so this PR ships only the 4.3 test
  artifact. The three test assertions exercise: (a) default path fallback to
  `${HOME}/Projects/AmitTiwari/bookshelf` containing `bookshelf`,
  (b) `BOOKSHELF_REPO` env override returning the override value verbatim,
  (c) `BOOKSHELF_REPO_STRICT=1` returning exit code 2 when `$repo/.git` is
  missing.
- Task 4.2 under parallel-worktree orchestration: the plan prescribes only
  the test file `tests/cli/test_slug.zsh`, sourcing the `bookshelf_slug`
  helper landed by Task 4.1. Running the prescribed test against the 4.1
  worker's `lib/_shared.zsh` on macOS (BSD iconv) revealed an exit-code bug:
  BSD iconv returns 1 when emitting a "warning: invalid characters" line
  even though it successfully transliterated (`Sōseki` → `Soseki`,
  `Flow — …` → `Flow - …`). The plan-shipped pattern
  `s=$(... iconv ...) || s="$title"` consumed that exit-1 only in the title
  block (and in doing so concatenated the un-transliterated fallback in the
  author block where `||` lived inside the pipeline); under `set -e` the
  errexit path was also tripped via the assignment status. Per TDD ("failing
  test → fix impl → pass"), this worker landed a minimal `_shared.zsh`
  patch alongside `tests/cli/test_slug.zsh`: capture iconv with `|| true`
  inside `$()` to be errexit-safe, and fall back to the original input only
  on empty output rather than non-zero exit. Verification: with the Phase 3
  harness (`tests/_assert.zsh`, `tests/run.zsh`) and Task 4.1's
  `tests/cli/test_ulid.zsh` temporarily checked out into the working tree,
  `zsh tests/run.zsh` reports `2 passed, 0 failed, 0 skipped`; those
  borrowed files are then removed so this PR ships only the slug test +
  the `_shared.zsh` macOS-iconv hardening. If this PR merges after 4.1,
  the `_shared.zsh` diff lands as a small follow-up over the 4.1 baseline;
  if merge order swaps, treat 4.2's `_shared.zsh` as the canonical version
  during conflict resolution.
- Task 4.1 under parallel-worktree orchestration: the plan bundles every
  Phase 4 sub-task into one commit at Task 4.5 (`feat(lib): _shared.zsh —
  ulid, slug, repo path, length guard`) covering `lib/_shared.zsh` +
  `tests/cli/test_{ulid,slug,repo_resolve,length_guard}.zsh`. For per-task
  PR isolation, this worker lands `lib/_shared.zsh` (the full file
  per-plan, since it contains all four functions) plus
  `tests/cli/test_ulid.zsh` as `feat(lib): _shared.zsh + test_ulid.zsh —
  ulid helper (Task 4.1)`. Subsequent 4.2/4.3/4.4 workers add only their
  respective test file; the bundle commit message at 4.5 then serves as
  the named bundle marker with no further file changes. Verification was
  done locally by checking out the Phase 3 harness (`tests/_assert.zsh`
  from `origin/ralph-devin/3-1-...`, `tests/run.zsh` from `origin/...3-2-...`)
  into the working tree, running `zsh tests/run.zsh` (`1 passed`), then
  removing those files before committing so this PR ships only the 4.1
  artifacts; the harness arrives via its own merged PRs.
- Task 3.2 under parallel-worktree orchestration: landed `tests/run.zsh`
  alone as `test(harness): run.zsh — test runner (Task 3.2)`, mirroring
  Task 3.1's split commit. Empty-dir smoke-test produced the plan-expected
  `0 passed, 0 failed, 0 skipped` (exit 0); additional ad-hoc smoke with
  pass/fail/skip fixtures confirmed PASS/FAIL/SKIP routing, indented
  failure-output framing, and non-zero exit on any failure — fixtures
  removed before committing.
- Task 3.1 under parallel-worktree orchestration: the plan bundles
  `tests/_assert.zsh` into Task 3.2's commit (`test: harness — runner +
  assertions + temp-repo helpers`). For per-task PR isolation, this worker
  lands `tests/_assert.zsh` as its own commit `test(harness): _assert.zsh
  — assertions + temp-repo helpers (Task 3.1)`; Task 3.2's worker will land
  `tests/run.zsh` separately. The plan-named bundle commit message is
  therefore distributed across two commits, mirroring the Phase 1/2 split
  pattern already documented below.
- Task 0.1 verification under parallel worktree orchestration: `git status
  --porcelain` on the main worktree may show `.ralph/fix_plan.md` modified
  due to orchestrator `[~]` in-progress markers on sibling tasks. Treat that
  as transient orchestration metadata, not project drift. Verify branch is
  `main` and that no non-`.ralph/fix_plan.md` paths are dirty.
- Task 2.4 under parallel-worktree orchestration: the plan prescribes a
  single bundle commit `feat: closed category taxonomy + open shelves hint
  file + template` covering `books/_categories.yml books/_shelves.yml
  books/_example.md`. That commit (`c3027d9`) already exists on `main` —
  landed by a prior Ralph worker via merged PR #6. The three files match
  the plan-specified content. Task 2.4's worker commit therefore only
  ticks the checkbox; no file content changes are required at 2.4.
- Task 1.6 under parallel-worktree orchestration: the plan prescribes a
  single bundle commit `chore: bootstrap bookshelf corpus` covering
  `LICENSE README.md AGENTS.md CLAUDE.md .gitignore` + this plan file. In
  practice the orchestrator landed each Phase 1 sub-task (1.1–1.5) as its
  own merge commit, and the plan file itself was already committed in the
  initial seed commit `d1c0aa2 chore(bootstrap): seed ralph workflow for
  bookshelf`. The bundle is therefore distributed across history rather
  than concentrated in one commit; Task 1.6's worker commit serves as the
  named bundle marker. No file content changes are required at 1.6.
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
