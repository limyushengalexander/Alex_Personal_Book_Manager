#!/usr/bin/env bash
# Exercise the real screen/workflows with scripted selections, not Gum rendering.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
temporary=$(mktemp -d)
trap 'rm -rf "$temporary"' EXIT
export BOOK_DB="$temporary/books.csv"
export BOOK_INTERESTS="$ROOT/config/interests.txt"
export SCREEN_LOG="$temporary/screen.log"
mkdir "$temporary/bin"
cat > "$temporary/bin/gum" <<'GUM'
#!/usr/bin/env bash
set -euo pipefail
case "$1" in
    style) printf '%s\n' "$@" >> "$SCREEN_LOG" ;;
    choose) IFS= read -r choice; printf '%s\n' "$choice" ;;
    confirm) exit 0 ;;
    *) exit 2 ;;
esac
GUM
chmod +x "$temporary/bin/gum"
export PATH="$temporary/bin:$PATH"
# The first run starts empty; the next must exclude the book just saved.
for expected in 1 2; do
    bash "$ROOT/ui/recommendations_screen.sh" > "$temporary/output" 2> "$temporary/progress"
    grep -q 'Choose a suggestion' "$SCREEN_LOG"
    grep -q '^\[refining\]' "$temporary/progress"
    [[ $(grep -c '^\[done\]' "$temporary/progress") == 3 ]]
    if grep -q 'unbound variable' "$temporary/progress"; then exit 1; fi
    records=$(bash "$ROOT/data/book_database.sh" list)
    [[ $(printf '%s\n' "$records" | wc -l | tr -d ' ') == "$expected" ]]
    printf '%s\n' "$records" | awk -F '|' 'NF!=8 || $6!="want-to-read" || $8!="no" {exit 1}'
done
printf 'PASS: recommendation screen displays and saves results with empty and populated libraries.\n'
