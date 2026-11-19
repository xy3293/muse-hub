#!/usr/bin/env python3
"""Fetch public GitHub Trending snapshots with only the Python standard library."""
import json
import random
import re
import sys
import time
from datetime import datetime, timezone
from html.parser import HTMLParser
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parent.parent
LANGUAGES = ("global", "Python", "TypeScript", "Rust", "Go")


class TrendingParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.rows = []
        self.row = None
        self.heading = False
        self.capture = None
        self.parts = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "article" and "Box-row" in attrs.get("class", "").split():
            self.row = {"repository": None, "language": None, "description": "", "stars": None}
        elif self.row is not None:
            if tag == "h2":
                self.heading = True
            elif tag == "a" and self.heading:
                self.row["repository"] = attrs.get("href", "").lstrip("/")
            elif tag == "p":
                self.capture, self.parts = "description", []
            elif tag == "span" and attrs.get("itemprop") == "programmingLanguage":
                self.capture, self.parts = "language", []

    def handle_data(self, data):
        if self.row is not None:
            if self.capture:
                self.parts.append(data)
            match = re.search(r"([\d,]+) stars (?:today|this week)", data)
            if match:
                self.row["stars"] = int(match.group(1).replace(",", ""))

    def handle_endtag(self, tag):
        if self.row is None:
            return
        if tag == "h2":
            self.heading = False
        elif (tag == "p" and self.capture == "description") or (tag == "span" and self.capture == "language"):
            self.row[self.capture] = " ".join("".join(self.parts).split())
            self.capture = None
        elif tag == "article":
            if not self.row["repository"] or self.row["stars"] is None:
                raise ValueError("Incomplete Trending repository entry")
            self.rows.append(self.row)
            self.row = None


def fetch(url):
    for attempt in range(4):
        try:
            request = Request(url, headers={"User-Agent": "muse-hub-trending/1.0"})
            with urlopen(request, timeout=30) as response:
                print(f"HTTP {response.status} {url}", flush=True)
                return response.read().decode("utf-8")
        except HTTPError as exc:
            if exc.code != 429 and not 500 <= exc.code <= 599:
                raise
            if attempt == 3:
                raise
            delay = 2 ** (attempt + 1)
            print(f"HTTP {exc.code}: retry in {delay}s ({attempt + 1}/3)", file=sys.stderr, flush=True)
            time.sleep(delay)


def main():
    started = datetime.now(timezone.utc)
    rows = []
    for period in ("daily", "weekly"):
        for dimension in LANGUAGES:
            if rows:
                time.sleep(random.uniform(2, 5))
            path = "" if dimension == "global" else "/" + dimension.lower()
            url = f"https://github.com/trending{path}?since={period}"
            html = fetch(url)
            captured = datetime.now(timezone.utc).isoformat(timespec="seconds")
            parser = TrendingParser()
            parser.feed(html)
            if not parser.rows:
                raise ValueError(f"No repositories parsed from {url}")
            entries = parser.rows[:25]
            for entry in entries:
                entry.update(fetched_at=captured, period=period, language_dimension=dimension)
            rows.extend(entries)
            print(f"{period}/{dimension}: {len(entries)} entries", flush=True)
    if datetime.now(timezone.utc).date() != started.date():
        raise RuntimeError("UTC date changed during fetch; no file written")
    content = "".join(json.dumps(row, ensure_ascii=False, separators=(",", ":")) + "\n" for row in rows).encode("utf-8")
    if len(content) >= 200_000:
        raise RuntimeError(f"Daily data is {len(content)} bytes, at or above 200 KB; no file written")
    output = ROOT / "data" / "trending" / f"{started.date()}.jsonl"
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_suffix(".tmp")
    temporary.write_bytes(content)
    temporary.replace(output)
    print(f"Saved {len(rows)} entries from 10 lists to {output} ({len(content)} bytes)")


if __name__ == "__main__":
    main()
