#!/usr/bin/env bash
# End-to-end checks use a disposable database, never your personal library.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
temporary=$(mktemp -d)
trap 'rm -rf "$temporary"' EXIT
export BOOK_DB="$temporary/books.csv"
export BOOK_INTERESTS="$ROOT/config/interests.txt"
db="$ROOT/data/book_database.sh"
manage="$ROOT/workflows/manage_library.sh"
assert_equal() { [[ $1 == "$2" ]] || { printf 'FAIL: expected <%s>, got <%s>\n' "$2" "$1" >&2; exit 1; }; }
assert_equal "$(bash "$db" list)" ''
bash "$manage" add 'Thinking in Systems' 'Donella H. Meadows' finished 5 yes >/dev/null
assert_equal "$(bash "$db" list)" '1|Thinking in Systems|Donella H. Meadows|systems thinking|2008|finished|5|yes'
assert_equal "$(printf 'SYSTEMS\n' | bash "$ROOT/books/search_books.sh")" "$(bash "$db" list)"
if bash "$manage" add ' thinking IN systems ' 'Donella H. Meadows' reading '' yes 2>/dev/null; then exit 1; fi
if bash "$manage" add 'Bad|Title' Author reading '' yes 2>/dev/null; then exit 1; fi
bash "$manage" add 'A "book", with commas' 'An Author' reading '' no >/dev/null
bash "$db" exists 'A "book", with commas' 'An Author'
assert_equal "$(bash "$db" search 'commas')" '2|A "book", with commas|An Author|||reading||no'
if bash "$manage" rating 1 6 2>/dev/null; then exit 1; fi
if bash "$manage" status 1 invalid 2>/dev/null; then exit 1; fi
if bash "$manage" status 99 finished 2>/dev/null; then exit 1; fi
bash "$manage" status 2 finished >/dev/null
bash "$manage" rating 2 4 >/dev/null
bash "$manage" owned 2 yes >/dev/null
assert_equal "$(bash "$db" search commas)" '2|A "book", with commas|An Author|||finished|4|yes'
# Edits preserve reading fields and reject invalid changes without writing.
bash "$manage" edit 2 'Corrected "book", with commas' 'New Author' fiction 2000 >/dev/null
assert_equal "$(bash "$db" search commas)" '2|Corrected "book", with commas|New Author|fiction|2000|finished|4|yes'
before=$(cat "$BOOK_DB")
if bash "$manage" edit 2 ' thinking IN systems ' 'Donella H. Meadows' '' '' 2>/dev/null; then exit 1; fi
if bash "$manage" edit 2 Title Author fiction bad 2>/dev/null; then exit 1; fi
if bash "$manage" edit 2 '' Author '' '' 2>/dev/null; then exit 1; fi
if bash "$manage" edit 99 Title Author '' '' 2>/dev/null; then exit 1; fi
assert_equal "$(cat "$BOOK_DB")" "$before"
bash "$manage" edit 2 'Corrected "book", with commas' 'New Author' '' '' >/dev/null
assert_equal "$(bash "$db" search commas)" '2|Corrected "book", with commas|New Author|||finished|4|yes'
candidates=$'Thinking in Systems|Donella H. Meadows|systems thinking|2008|99|history|Already saved\nNew Book|Author|logistics|2001|80|interests|First\nnew book|author|logistics|2001|70|history|Duplicate\nNew Discovery|Other|fiction|2000|45|discovery|Explore'
result=$(printf '%s\n' "$candidates" | bash "$ROOT/recommendations/refine_recommendations.sh" 2)
assert_equal "$result" $'New Book|Author|logistics|2001|80|interests|First\nNew Discovery|Other|fiction|2000|45|discovery|Explore'
bash "$ROOT/workflows/get_recommendations.sh" > "$temporary/result" 2> "$temporary/progress"
assert_equal "$(wc -l < "$temporary/result" | tr -d ' ')" 5
awk -F '|' 'NF!=7 {exit 1} $1=="Thinking in Systems" {exit 1}' "$temporary/result"
grep -q '|history|' "$temporary/result"
grep -q '|discovery|' "$temporary/result"
assert_equal "$(grep -c '^\[done\]' "$temporary/progress")" 3
# A failed worker must cause the workflow to fail without returning a shortlist.
if BOOK_INTERESTS="$temporary/missing" bash "$ROOT/workflows/get_recommendations.sh" > "$temporary/failed" 2>/dev/null; then exit 1; fi
assert_equal "$(cat "$temporary/failed")" ''
printf 'PASS: storage, validation, metadata, piped search, refinement and recommendation workflow.\n'
