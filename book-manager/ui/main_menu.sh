#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
while true; do
    gum style --border rounded --padding '1 2' --foreground 81 'THE READING ROUTE' 'A personal shelf for curious systems thinkers'
    action=$(gum choose 'Browse Library' 'Add Book' 'Search Library' 'Get Recommendations' 'Quit') || exit 0
    case "$action" in
        'Browse Library') bash "$ROOT/ui/library_screen.sh" browse || true ;;
        'Add Book') bash "$ROOT/ui/library_screen.sh" add || true ;;
        'Search Library') bash "$ROOT/ui/library_screen.sh" search || true ;;
        'Get Recommendations') bash "$ROOT/ui/recommendations_screen.sh" || true ;;
        Quit) exit 0 ;;
    esac
done
