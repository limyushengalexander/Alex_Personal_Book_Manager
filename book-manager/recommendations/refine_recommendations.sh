#!/usr/bin/env bash
# Read candidates on stdin. Keep each book's highest score, exclude saved
# books, and reserve one place for discovery when a discovery candidate exists.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
limit=${1:-5}
[[ $limit =~ ^[1-9][0-9]?$ ]] || { echo 'Limit must be 1..99.' >&2; exit 2; }
snapshot=$(mktemp)
trap 'rm -f "$snapshot"' EXIT
bash "$ROOT/data/book_database.sh" list > "$snapshot"
awk -F '|' '
function norm(s) {gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); gsub(/[[:space:]]+/, " ", s); return tolower(s)}
FILENAME==ARGV[1] {saved[norm($2) SUBSEP norm($3)]=1; next}
NF==7 && $5 ~ /^[0-9]+$/ {
    k=norm($1) SUBSEP norm($2)
    if (!(k in saved) && (!(k in scores) || $5>scores[k])) {scores[k]=$5; rows[k]=$0}
}
END {for (k in rows) print rows[k]}
' "$snapshot" - | LC_ALL=C sort -t '|' -k5,5nr -k1,1 -k2,2 | awk -F '|' -v limit="$limit" '
{rows[++n]=$0; if ($6=="discovery" && !discovery) discovery=n}
END {
    count=(n<limit ? n : limit)
    for (i=1;i<=count;i++) {
        if (i==count && discovery>count) print rows[discovery]
        else print rows[i]
    }
}'
