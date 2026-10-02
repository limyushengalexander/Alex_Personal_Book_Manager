#!/usr/bin/env bash
# Entry point: check dependencies, then hand control to the UI.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
for dependency in gum python3 awk sort; do
    command -v "$dependency" >/dev/null || {
        printf 'Missing %s. See README.md for setup.\n' "$dependency" >&2
        exit 1
    }
done
exec bash "$ROOT/ui/main_menu.sh"
