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
