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
