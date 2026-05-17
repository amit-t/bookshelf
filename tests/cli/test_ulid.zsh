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
