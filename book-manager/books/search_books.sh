#!/usr/bin/env bash
# Accept a term as an argument or as one line on stdin.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
if [[ $# == 1 ]]; then term=$1
elif [[ $# == 0 ]]; then IFS= read -r term || [[ -n ${term:-} ]]
else echo 'Usage: search_books.sh [TERM]' >&2; exit 2
fi
exec bash "$ROOT/data/book_database.sh" search "$term"
