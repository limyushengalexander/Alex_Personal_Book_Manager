#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
gum style --foreground 81 'Finding your next reading route...'
records=$(bash "$ROOT/workflows/get_recommendations.sh")
[[ -n $records ]] || { gum style 'No new candidates. Expand books/catalog.psv.'; exit 0; }
gum style 'Choose a suggestion (Enter shows details):'
# Keep menu labels short; use the row number to retrieve the complete record.
choices=$(printf '%s\n' "$records" | awk -F '|' '{print NR ". " $1 " by " $2}')
choice=$(printf '%s\n' "$choices" | gum choose) || exit 0
row_number=${choice%%.*}
selected=$(printf '%s\n' "$records" | awk -v row="$row_number" 'NR==row')
IFS='|' read -r title author genre year score strategy reason <<< "$selected"
gum style --border rounded --padding '1 2' "$title" "by $author" "$genre ($year)" "$reason"
if gum confirm 'Save to your want-to-read list?'; then
    bash "$ROOT/workflows/manage_library.sh" add "$title" "$author" want-to-read '' no
fi
