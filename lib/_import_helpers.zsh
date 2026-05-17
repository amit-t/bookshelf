#!/usr/bin/env zsh
# Render a book entry to books/<slug>.md with full frontmatter + body sections.
# Echoes path on stdout.

_bookshelf_yaml_array() {
  local csv="$1"
  if [[ -z "$csv" ]]; then
    print -r -- "[]"
    return
  fi
  local out="[" first=1
  local IFS=','
  local item
  for item in ${=csv}; do
    item="${item## }"; item="${item%% }"
    if (( first )); then
      out+="$item"; first=0
    else
      out+=", $item"
    fi
  done
  out+="]"
  print -r -- "$out"
}

_bookshelf_yaml_quote() {
  local v="$1"
  if [[ -z "$v" ]]; then print -r -- '""'; return; fi
  if [[ "$v" == *:* || "$v" == *\#* || "$v" == \-* || "$v" == \?* ]]; then
    v="${v//\"/\\\"}"
    print -r -- "\"$v\""
  else
    print -r -- "\"$v\""
  fi
}

# Optional quoted string: prints "value" when set, null when empty.
# (The plan's inline `${v:+\"$v\"}${v:-null}` pattern duplicates the value
# when set, because `${v:-null}` returns $v — not "null" — for set values,
# yielding `"foo"foo`. This helper produces correct YAML in both branches.)
_bookshelf_yaml_str_or_null() {
  local v="$1"
  if [[ -z "$v" ]]; then print -r -- "null"; return; fi
  print -r -- "\"$v\""
}

bookshelf_write_record() {
  local title="" subtitle="" slug="" authors_csv="" isbn13="" published_year="" pages=""
  local language="en" cover_url="" goodreads_url="" amazon_url="" format="" genre=""
  local book_status="read" started_at="" finished_at="" rating="" category="life"
  local tags_csv="" shelves_csv="" recommended_by="" who_should_read="" published=""
  local summary="" learnings="" passages="" notes="" origin="manual"
  local wisdom_ids_csv=""

  while (( $# )); do
    case "$1" in
      --title)            title="$2"; shift 2 ;;
      --subtitle)         subtitle="$2"; shift 2 ;;
      --slug)             slug="$2"; shift 2 ;;
      --authors-csv)      authors_csv="$2"; shift 2 ;;
      --isbn13)           isbn13="$2"; shift 2 ;;
      --published-year)   published_year="$2"; shift 2 ;;
      --pages)            pages="$2"; shift 2 ;;
      --language)         language="$2"; shift 2 ;;
      --cover-url)        cover_url="$2"; shift 2 ;;
      --goodreads-url)    goodreads_url="$2"; shift 2 ;;
      --amazon-url)       amazon_url="$2"; shift 2 ;;
      --format)           format="$2"; shift 2 ;;
      --genre)            genre="$2"; shift 2 ;;
      --status)           book_status="$2"; shift 2 ;;
      --started-at)       started_at="$2"; shift 2 ;;
      --finished-at)      finished_at="$2"; shift 2 ;;
      --rating)           rating="$2"; shift 2 ;;
      --category)         category="$2"; shift 2 ;;
      --tags-csv)         tags_csv="$2"; shift 2 ;;
      --shelves-csv)      shelves_csv="$2"; shift 2 ;;
      --recommended-by)   recommended_by="$2"; shift 2 ;;
      --who-should-read)  who_should_read="$2"; shift 2 ;;
      --published)        published="$2"; shift 2 ;;
      --summary)          summary="$2"; shift 2 ;;
      --learnings)        learnings="$2"; shift 2 ;;
      --passages)         passages="$2"; shift 2 ;;
      --notes)            notes="$2"; shift 2 ;;
      --origin)           origin="$2"; shift 2 ;;
      --wisdom-ids-csv)   wisdom_ids_csv="$2"; shift 2 ;;
      *) print -r -- "write_record: unknown flag $1" >&2; return 1 ;;
    esac
  done

  [[ -z "$title" || -z "$slug" ]] && { print -r -- "write_record: --title and --slug required" >&2; return 1; }

  # Default `published` based on status
  if [[ -z "$published" ]]; then
    if [[ "$book_status" == "read" ]]; then published="true"; else published="false"; fi
  fi

  local repo id now
  repo=$(bookshelf_repo_path) || return 2
  id=$(bookshelf_ulid)
  now=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
  mkdir -p "$repo/books"
  local out="$repo/books/$slug.md"

  local authors_yaml tags_yaml shelves_yaml wisdom_yaml
  authors_yaml=$(_bookshelf_yaml_array "$authors_csv")
  tags_yaml=$(_bookshelf_yaml_array "$tags_csv")
  shelves_yaml=$(_bookshelf_yaml_array "$shelves_csv")
  wisdom_yaml=$(_bookshelf_yaml_array "$wisdom_ids_csv")

  {
    print -r -- "---"
    print -r -- "id: $id"
    print -r -- "slug: $slug"
    print -r -- "title: $(_bookshelf_yaml_quote "$title")"
    print -r -- "subtitle: $(_bookshelf_yaml_quote "$subtitle")"
    print -r -- "authors: $authors_yaml"
    print -r -- "isbn13: $(_bookshelf_yaml_str_or_null "$isbn13")"
    print -r -- "published_year: ${published_year:-null}"
    print -r -- "pages: ${pages:-null}"
    print -r -- "language: $language"
    print -r -- "cover_url: $(_bookshelf_yaml_str_or_null "$cover_url")"
    print -r -- "goodreads_url: $(_bookshelf_yaml_str_or_null "$goodreads_url")"
    print -r -- "amazon_url: $(_bookshelf_yaml_str_or_null "$amazon_url")"
    print -r -- "format: $(_bookshelf_yaml_str_or_null "$format")"
    print -r -- "genre: $(_bookshelf_yaml_str_or_null "$genre")"
    print -r -- "status: $book_status"
    print -r -- "started_at: ${started_at:-null}"
    print -r -- "finished_at: ${finished_at:-null}"
    print -r -- "rating: ${rating:-null}"
    print -r -- "category: $category"
    print -r -- "tags: $tags_yaml"
    print -r -- "shelves: $shelves_yaml"
    print -r -- "recommended_by: $(_bookshelf_yaml_str_or_null "$recommended_by")"
    print -r -- "who_should_read: $(_bookshelf_yaml_quote "$who_should_read")"
    print -r -- "published: $published"
    print -r -- "created_at: $now"
    print -r -- "updated_at: $now"
    print -r -- "import_origin: $origin"
    print -r -- "wisdom_ids: $wisdom_yaml"
    print -r -- "---"
    print -r --
    print -r -- "## Summary"
    print -r --
    [[ -n "$summary" ]] && print -r -- "$summary" || print -r -- "_TBD_"
    print -r --
    print -r -- "## Top Learnings"
    print -r --
    if [[ -n "$learnings" ]]; then
      print -r -- "${learnings//\\n/$'\n'}"
    fi
    print -r --
    print -r -- "## Favorite Passages"
    print -r --
    if [[ -n "$passages" ]]; then
      print -r -- "${passages//\\n/$'\n'}"
    fi
    print -r --
    print -r -- "## Notes"
    print -r --
    [[ -n "$notes" ]] && print -r -- "$notes"
  } > "$out"

  print -r -- "$out"
}
