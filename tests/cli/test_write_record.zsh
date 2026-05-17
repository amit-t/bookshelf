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
