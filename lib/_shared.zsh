#!/usr/bin/env zsh
# Shared helpers for bookshelf CLI. Functions are prefixed with `bookshelf_`.

_BOOKSHELF_ULID_ALPHABET="0123456789abcdefghjkmnpqrstvwxyz"

bookshelf_ulid() {
  local ms hex i v out=""
  if (( $+commands[gdate] )); then
    ms=$(gdate +%s%3N)
  else
    local s ns
    s=$(date +%s)
    ns=$(date +%N 2>/dev/null)
    if [[ -z "$ns" || "$ns" == "N" ]]; then
      ms=$((s * 1000))
    else
      ms=$((s * 1000 + ${ns:0:3}))
    fi
  fi
  local t=$ms
  for i in {1..10}; do
    v=$(( t % 32 ))
    out="${_BOOKSHELF_ULID_ALPHABET:$v:1}${out}"
    t=$(( t / 32 ))
  done
  hex=$(head -c 10 /dev/urandom | od -An -tx1 | tr -d ' \n')
  local bits="" b
  for (( i=0; i<${#hex}; i+=2 )); do
    b=$(printf '%08d' "$(echo "obase=2; ibase=16; ${(U)hex[$((i+1)),$((i+2))]}" | bc)")
    bits+="$b"
  done
  local r=""
  for (( i=0; i<80; i+=5 )); do
    v=$(( 2#${bits:$i:5} ))
    r+="${_BOOKSHELF_ULID_ALPHABET:$v:1}"
  done
  print -r -- "${out}${r}"
}

_BOOKSHELF_DEFAULT_REPO="${HOME}/Projects/AmitTiwari/bookshelf"

bookshelf_repo_path() {
  local strict="${BOOKSHELF_REPO_STRICT:-0}"
  local p="${BOOKSHELF_REPO:-$_BOOKSHELF_DEFAULT_REPO}"
  if [[ "$strict" == "1" && ! -d "$p/.git" ]]; then
    print -r -- "bookshelf: repo not found at $p (set BOOKSHELF_REPO)" >&2
    return 2
  fi
  print -r -- "$p"
}

bookshelf_cd_repo() {
  local p
  p=$(BOOKSHELF_REPO_STRICT=1 bookshelf_repo_path) || return $?
  cd "$p" || return 2
}

# Slug: lowercase, ASCII-transliterated, strip leading article + subtitle, kebab,
# cap 80 chars, then append `-<author-last-kebab>` (caller responsibility to
# pass the cleaned author last).
#
# Args: $1 = title, $2 = author last name
bookshelf_slug() {
  local title="$1" author_last="$2"
  local s
  # transliterate Unicode to ASCII; fall back to original on iconv failure.
  # macOS BSD iconv returns exit 1 when it emits a warning even though it
  # still produced valid transliterated output, so we cannot rely on the
  # exit code alone — `|| true` inside the substitution keeps callers under
  # `set -e` safe, and we then check for empty output to decide fallback.
  if (( $+commands[iconv] )); then
    s=$(print -r -- "$title" | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null || true)
    [[ -z "$s" ]] && s="$title"
  else
    s="$title"
  fi
  # drop subtitle: anything after `:` or ` — ` or ` - `
  s=$(print -r -- "$s" | sed -E 's/[:—].*$//; s/ - .*$//')
  # lowercase
  s=$(print -r -- "$s" | tr '[:upper:]' '[:lower:]')
  # strip leading article
  s=$(print -r -- "$s" | sed -E 's/^(the|a|an) +//')
  # non-alphanum -> hyphen
  s=$(print -r -- "$s" | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')
  # cap title portion
  s="${s:0:80}"
  if [[ -n "$author_last" ]]; then
    local al
    # Same macOS-iconv caveat as the title block above: `|| true` masks BSD
    # iconv's exit-1-on-warning so callers under `set -e` aren't tripped, and
    # we fall back to the original input only when iconv produced no output.
    if (( $+commands[iconv] )); then
      al=$(print -r -- "$author_last" | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null || true)
      [[ -z "$al" ]] && al="$author_last"
    else
      al="$author_last"
    fi
    al=$(print -r -- "$al" | tr '[:upper:]' '[:lower:]' \
      | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')
    [[ -n "$al" ]] && s="${s}-${al}"
  fi
  print -r -- "$s"
}

_BOOKSHELF_TITLE_MIN=2
_BOOKSHELF_TITLE_MAX=500

bookshelf_check_title() {
  local title="$1"
  local n=${#title}
  if (( n < _BOOKSHELF_TITLE_MIN )); then
    print -r -- "bookshelf: title too short ($n chars; min $_BOOKSHELF_TITLE_MIN)" >&2
    return 6
  fi
  if (( n > _BOOKSHELF_TITLE_MAX )); then
    print -r -- "bookshelf: title too long ($n chars; max $_BOOKSHELF_TITLE_MAX)" >&2
    return 6
  fi
  return 0
}

# Find an existing book file by slug. Prints path on stdout, empty if none.
bookshelf_find_by_slug() {
  local slug="$1"
  local repo="${2:-$(bookshelf_repo_path)}"
  local f="$repo/books/$slug.md"
  [[ -f "$f" ]] && print -r -- "$f"
}
