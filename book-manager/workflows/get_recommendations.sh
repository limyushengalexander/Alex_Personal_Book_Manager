#!/usr/bin/env bash
# stdout is records only; stderr carries live progress, so pipes stay clean.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
temporary=$(mktemp -d)
pids=()
cleanup() {
    for pid in "${pids[@]}"; do kill "$pid" 2>/dev/null || true; done
    rm -rf "$temporary"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
names=(history interests discovery)
programs=(recommend_from_history recommend_from_interests recommend_for_discovery)
for i in 0 1 2; do
    printf '[running] %s\n' "${names[$i]}" >&2
    bash "$ROOT/recommendations/${programs[$i]}.sh" > "$temporary/${names[$i]}" &
    pids+=("$!")
done
# All workers are launched BEFORE any wait. Report completion in launch order.
failed=0
for i in 0 1 2; do
    if wait "${pids[$i]}"; then
        printf '[done]    %s\n' "${names[$i]}" >&2
    else
        printf '[failed]  %s\n' "${names[$i]}" >&2
        failed=1
    fi
done
pids=()
[[ $failed == 0 ]] || exit 1
printf '[refining] Removing duplicates and saved books...\n' >&2
cat "$temporary/history" "$temporary/interests" "$temporary/discovery" |
    bash "$ROOT/recommendations/refine_recommendations.sh" "${1:-5}"
