#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"
if [[ "$(git branch --show-current)" != "main" ]]; then
    echo "Run the daily job from the main branch" >&2
    exit 1
fi
if [[ -n "$(git status --porcelain)" ]]; then
    echo "Working tree must be clean before the daily job" >&2
    exit 1
fi
python3 trending/fetch_trending.py
data_file="data/trending/$(date -u +%F).jsonl"
git add -- "$data_file"
if ! git diff --cached --quiet -- "$data_file"; then
    git commit -m "Update GitHub Trending data $(date -u +%F)" -- "$data_file"
fi
if ! git push origin main; then
    echo "Failed to push Trending data to origin/main" >&2
    exit 1
fi
