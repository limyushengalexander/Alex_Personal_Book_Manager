#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
awk -F '|' '
FILENAME==ARGV[1] {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "")
    if ($0!="" && $0 !~ /^#/) interests[tolower($0)]=1
    next
}
{score=0; topic=""
 for (interest in interests) if (index(tolower($1 " " $3), interest)) {
     score++; if (topic=="" || interest<topic) topic=interest
 }
 if (score) print $0 "|" 70+score*5 "|interests|Matches your interest: " topic
}' "${BOOK_INTERESTS:-$ROOT/config/interests.txt}" "$ROOT/books/catalog.psv"
