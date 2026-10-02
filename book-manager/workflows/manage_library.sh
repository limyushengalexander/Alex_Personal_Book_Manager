#!/usr/bin/env bash
# Coordinates metadata/search with the database; never opens storage itself.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
action=${1:-}; [[ $# -gt 0 ]] && shift
case "$action" in
    add)
        [[ $# == 5 ]] || { echo 'Usage: manage_library.sh add TITLE AUTHOR STATUS RATING OWNED' >&2; exit 2; }
        for value in "$@"; do
            if [[ $value == *'|'* || $value =~ [[:cntrl:]] ]]; then
                echo 'Fields cannot contain pipes or control characters.' >&2; exit 2
            fi
        done
        metadata=$(bash "$ROOT/books/fetch_book_metadata.sh" "$1" "$2")
        IFS='|' read -r title author genre year <<< "$metadata"
        bash "$ROOT/data/book_database.sh" add "$title" "$author" "$genre" "$year" "$3" "$4" "$5"
        ;;
    search) exec bash "$ROOT/books/search_books.sh" "$@" ;;
    list|edit|status|rating|owned) exec bash "$ROOT/data/book_database.sh" "$action" "$@" ;;
    *) echo 'Use add, list, search, edit ID TITLE AUTHOR GENRE YEAR, status, rating or owned.' >&2; exit 2 ;;
esac
