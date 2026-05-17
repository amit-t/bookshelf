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
