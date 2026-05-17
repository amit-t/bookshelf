#!/usr/bin/env zsh
# Book metadata lookup. Open Library primary, Google Books fallback.
# If BOOKSHELF_LOOKUP_FIXTURES is set, reads from filesystem instead of network.

# Slugify title for fixture filename: lowercase, kebab, non-alphanum -> hyphen.
_bookshelf_fixture_slug() {
  print -r -- "$1" \
    | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

bookshelf_lookup_openlibrary() {
  local title="$1"
  local fixtures="${BOOKSHELF_LOOKUP_FIXTURES:-}"
  if [[ -n "$fixtures" ]]; then
    local slug
    slug=$(_bookshelf_fixture_slug "$title")
    local f="$fixtures/openlibrary/$slug.json"
    if [[ -f "$f" ]]; then
      cat "$f"
      return 0
    fi
    cat "$fixtures/openlibrary/no-match.json"
    return 0
  fi
  if ! (( $+commands[curl] )); then
    print -r -- "bookshelf: curl required for Open Library lookup" >&2
    return 4
  fi
  local q
  q=$(print -r -- "$title" | sed -E 's/ /+/g')
  curl -sS --max-time 8 "https://openlibrary.org/search.json?title=${q}&limit=3"
}

bookshelf_lookup_googlebooks() {
  local title="$1"
  local fixtures="${BOOKSHELF_LOOKUP_FIXTURES:-}"
  if [[ -n "$fixtures" ]]; then
    local slug
    slug=$(_bookshelf_fixture_slug "$title")
    local f="$fixtures/googlebooks/$slug.json"
    if [[ -f "$f" ]]; then
      cat "$f"
      return 0
    fi
    print -r -- '{"totalItems": 0, "items": []}'
    return 0
  fi
  if ! (( $+commands[curl] )); then
    print -r -- "bookshelf: curl required for Google Books lookup" >&2
    return 4
  fi
  local q
  q=$(print -r -- "$title" | sed -E 's/ /+/g')
  local url="https://www.googleapis.com/books/v1/volumes?q=intitle:${q}&maxResults=3"
  [[ -n "${GOOGLE_BOOKS_API_KEY:-}" ]] && url+="&key=${GOOGLE_BOOKS_API_KEY}"
  curl -sS --max-time 8 "$url"
}

# Combined lookup: try Open Library; if numFound=0, fall through to Google Books.
# Echoes a normalized JSON object on stdout:
#   {"source": "openlibrary|googlebooks|none", "title": ..., "authors": [...], ...}
# Requires jq.
bookshelf_lookup() {
  local title="$1"
  if ! (( $+commands[jq] )); then
    print -r -- "bookshelf: jq required to normalize lookup output" >&2
    return 4
  fi
  local ol gb
  ol=$(bookshelf_lookup_openlibrary "$title") || return $?
  local n
  n=$(print -r -- "$ol" | jq -r '.numFound // 0')
  if (( n > 0 )); then
    print -r -- "$ol" | jq '{
      source: "openlibrary",
      title: .docs[0].title,
      authors: (.docs[0].author_name // []),
      published_year: .docs[0].first_publish_year,
      pages: .docs[0].number_of_pages_median,
      isbn13: ((.docs[0].isbn // []) | map(select(length == 13)) | .[0]),
      cover_id: .docs[0].cover_i,
      language: ((.docs[0].language // []) | .[0])
    }'
    return 0
  fi
  gb=$(bookshelf_lookup_googlebooks "$title") || return $?
  local m
  m=$(print -r -- "$gb" | jq -r '.totalItems // 0')
  if (( m > 0 )); then
    print -r -- "$gb" | jq '{
      source: "googlebooks",
      title: .items[0].volumeInfo.title,
      subtitle: .items[0].volumeInfo.subtitle,
      authors: (.items[0].volumeInfo.authors // []),
      published_year: (.items[0].volumeInfo.publishedDate | (.[0:4] // null) | tonumber? // null),
      pages: .items[0].volumeInfo.pageCount,
      isbn13: ((.items[0].volumeInfo.industryIdentifiers // []) | map(select(.type == "ISBN_13")) | .[0].identifier),
      cover_url: .items[0].volumeInfo.imageLinks.thumbnail,
      language: .items[0].volumeInfo.language
    }'
    return 0
  fi
  print -r -- '{"source": "none"}'
}
