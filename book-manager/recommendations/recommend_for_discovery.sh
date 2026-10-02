#!/usr/bin/env bash
# Explore genres absent from both the saved library and stated interests.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
library=$(bash "$ROOT/data/book_database.sh" list)
printf '%s\n' "$library" | awk -F '|' '
FILENAME=="-" {if (NF==8) genres[tolower($4)]=1; next}
FILENAME==ARGV[2] {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "")
    if ($0!="" && $0 !~ /^#/) interests[tolower($0)]=1
    next
}
{known=(tolower($3) in genres)
 for (interest in interests) if (index(tolower($1 " " $3), interest)) known=1
 if (!known) print $0 "|45|discovery|Explore a genre outside your current library and interests"
}' - "${BOOK_INTERESTS:-$ROOT/config/interests.txt}" "$ROOT/books/catalog.psv"
