#!/usr/bin/env bash
# Candidate contract: title|author|genre|year|score|strategy|reason
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
library=$(bash "$ROOT/data/book_database.sh" list)
printf '%s\n' "$library" | awk -F '|' '
FILENAME=="-" {
    if (NF==8 && $4!="" && ($7=="" || $7>=3)) {
        weight=($6=="finished" ? 3 : 1)+($7=="" ? 0 : $7)
        genre[tolower($4)]+=weight; author[tolower($3)]+=weight
    }
    next
}
{score=genre[tolower($3)]+author[tolower($2)]
 if (score>0) print $0 "|" 70+score "|history|Matches an author or genre in your saved books"}
' - "$ROOT/books/catalog.psv"
