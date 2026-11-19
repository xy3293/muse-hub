#!/usr/bin/env python3
"""Sum available daily Trending observations for a repository in a UTC calendar week."""
import argparse
import json
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

DATA = Path(__file__).resolve().parent.parent / "data" / "trending"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repository", help="repository full name, e.g. owner/name")
    parser.add_argument("--date", type=date.fromisoformat, default=datetime.now(timezone.utc).date(), help="UTC week containing YYYY-MM-DD (default: today UTC)")
    args = parser.parse_args()
    start = args.date - timedelta(days=args.date.weekday())
    total = 0
    observed = []
    missing = []
    for offset in range(7):
        day = start + timedelta(days=offset)
        path = DATA / f"{day}.jsonl"
        if not path.exists():
            missing.append(str(day))
            continue
        with path.open(encoding="utf-8") as handle:
            matches = [json.loads(line) for line in handle if line.strip()]
        matches = [row for row in matches if row["repository"].casefold() == args.repository.casefold() and row["period"] == "daily"]
        if matches:
            # One observation per day: prefer the global list; otherwise use the latest capture.
            row = max(matches, key=lambda item: (item["language_dimension"] == "global", item["fetched_at"]))
            total += row["stars"]
            observed.append(str(day))
    print(f"{args.repository} | UTC week {start} to {start + timedelta(days=6)}")
    print(f"Observed daily Trending star gains: {total} (observed on {len(observed)} days: {', '.join(observed) or 'none'})")
    print(f"Missing data files: {', '.join(missing) or 'none'}")
    print("Only observed daily Trending entries are summed; missing or unlisted days are unknown, and daily counts are rolling windows.")


if __name__ == "__main__":
    main()
