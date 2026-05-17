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
