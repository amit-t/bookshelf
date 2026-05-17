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
