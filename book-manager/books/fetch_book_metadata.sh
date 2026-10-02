#!/usr/bin/env bash
# Input: title author. Output: title|author|genre|year (one record).
# Offline enrichment: unknown titles retain blank genre/year, never invented.
set -euo pipefail
HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
[[ $# == 2 ]] || { echo 'Usage: fetch_book_metadata.sh TITLE AUTHOR' >&2; exit 2; }
export LOOKUP_TITLE="$1" LOOKUP_AUTHOR="$2"
awk -F '|' '
function norm(s) {gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return tolower(s)}
norm($1)==norm(ENVIRON["LOOKUP_TITLE"]) && norm($2)==norm(ENVIRON["LOOKUP_AUTHOR"]) {print; found=1; exit}
END {if (!found) print ENVIRON["LOOKUP_TITLE"] "|" ENVIRON["LOOKUP_AUTHOR"] "||"}
' "$HERE/catalog.psv"
