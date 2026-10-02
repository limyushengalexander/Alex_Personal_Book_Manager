#!/usr/bin/env bash
# Collect user input and render records. Business operations go to workflows.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
workflow="$ROOT/workflows/manage_library.sh"
case "${1:-browse}" in
    add)
        title=$(gum input --placeholder 'Book title') || exit 0
        author=$(gum input --placeholder 'Author (as printed on the book)') || exit 0
        gum style 'Reading status:'
        status=$(gum choose want-to-read reading finished) || exit 0
        gum style 'Do you own this book?'
        owned=$(gum choose yes no) || exit 0
        record=$(bash "$workflow" add "$title" "$author" "$status" '' "$owned")
        printf 'Saved: %s\n' "$record"
        exit 0 ;;
    search)
        term=$(gum input --placeholder 'Search title, author, genre or status') || exit 0
        records=$(bash "$workflow" search "$term") ;;
    browse) records=$(bash "$workflow" list) ;;
    *) echo 'Use add, browse or search.' >&2; exit 2 ;;
esac
[[ -n $records ]] || { gum style 'No books found. Add a book from the main menu.'; exit 0; }
gum style 'Choose a book (Enter shows details):'
# Keep menu labels short; use the row number to retrieve the complete record.
choices=$(printf '%s\n' "$records" | awk -F '|' '{print NR ". " $2 " by " $3}')
choice=$(printf '%s\n' "$choices" | gum choose) || exit 0
row_number=${choice%%.*}
selected=$(printf '%s\n' "$records" | awk -v row="$row_number" 'NR==row')
IFS='|' read -r id title author genre year status rating owned <<< "$selected"
gum style --border rounded --padding '1 2' "$title" "by $author" \
    "Genre: ${genre:-unknown}  Year: ${year:-unknown}" \
    "Status: $status  Rating: ${rating:-unrated}  Owned: $owned"
action=$(gum choose 'Edit book details' 'Change status' 'Rate book' 'Change ownership' 'Back') || exit 0
case "$action" in
    'Edit book details')
        # Save only after all four prompts complete; Escape cancels the edit.
        title=$(gum input --header 'Title' --value "$title") || exit 0
        author=$(gum input --header 'Author' --value "$author") || exit 0
        genre=$(gum input --header 'Genre (may be blank)' --value "$genre") || exit 0
        year=$(gum input --header 'Year (four digits or blank)' --value "$year") || exit 0
        record=$(bash "$workflow" edit "$id" "$title" "$author" "$genre" "$year")
        printf 'Updated: %s\n' "$record" ;;
    'Change status')
        value=$(gum choose want-to-read reading finished) || exit 0
        bash "$workflow" status "$id" "$value" ;;
    'Rate book')
        value=$(gum choose 5 4 3 2 1 Unrated) || exit 0
        [[ $value != Unrated ]] || value=''
        bash "$workflow" rating "$id" "$value" ;;
    'Change ownership')
        value=$(gum choose yes no) || exit 0
        bash "$workflow" owned "$id" "$value" ;;
esac
