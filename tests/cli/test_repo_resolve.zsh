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
