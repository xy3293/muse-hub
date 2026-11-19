#!/usr/bin/env python3
"""Fetch public GitHub Trending snapshots with only the Python standard library."""
import argparse
import gzip
import json
import os
import random
import re
import sys
import tempfile
import time
from datetime import datetime, timezone
from html.parser import HTMLParser
from pathlib import Path
from http.client import HTTPException, IncompleteRead
from urllib.error import HTTPError, URLError
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
        status, length, received, decoded = "unknown", "unknown", 0, 0
        try:
            request = Request(url, headers={
                "User-Agent": "muse-hub-trending/1.0",
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                "Accept-Encoding": "gzip, deflate",
                "Connection": "keep-alive",
            })
            with urlopen(request, timeout=30) as response:
                status = response.status
                length = response.headers.get("Content-Length", "unknown")
                print(f"HTTP {response.status} {url}", flush=True)
                raw = response.read()
                received = len(raw)
                if response.headers.get("Content-Encoding") == "gzip":
                    raw = gzip.decompress(raw)
                decoded = len(raw)
                return raw.decode("utf-8")
        except HTTPError as exc:
            status = exc.code
            length = exc.headers.get("Content-Length", "unknown") if exc.headers else "unknown"
            print(f"Request failed: {type(exc).__name__}", file=sys.stderr, flush=True)
            if exc.code != 429 and not 500 <= exc.code <= 599:
                raise
            if attempt == 3:
                raise
            delay = 2 ** (attempt + 1)
            print(f"HTTP {exc.code}: retry in {delay}s ({attempt + 1}/3)", file=sys.stderr, flush=True)
            time.sleep(delay)
        except (URLError, HTTPException, TimeoutError, ConnectionError, EOFError, OSError) as exc:
            if isinstance(exc, IncompleteRead):
                received = len(exc.partial)
            print(f"Request failed: {type(exc).__name__}", file=sys.stderr, flush=True)
            if attempt == 3:
                raise
            delay = 2 ** (attempt + 1)
            print(f"Transport error {exc!r}: retry in {delay}s ({attempt + 1}/3)", file=sys.stderr, flush=True)
            time.sleep(delay)
        except Exception as exc:
            print(f"Request failed: {type(exc).__name__}", file=sys.stderr, flush=True)
            raise
        finally:
            print(f"Request {url} status={status} Content-Length={length} "
                  f"received={received} decompressed={decoded}", file=sys.stderr, flush=True)


def atomic_write(path, content):
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=path.parent, prefix=f".{path.name}.", delete=False) as stream:
            temporary = Path(stream.name)
            if path.suffix == ".jsonl":
                if path.exists():
                    mode = path.stat().st_mode & 0o777
                else:
                    mask = os.umask(0)
                    os.umask(mask)
                    mode = 0o666 & ~mask
                os.fchmod(stream.fileno(), mode)
            stream.write(content)
        os.replace(temporary, path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description="Fetch GitHub Trending snapshots for one UTC date.")
    parser.add_argument("--date", default=None, help="UTC date (YYYY-MM-DD) to fetch for; defaults to today")
    args = parser.parse_args()
    if args.date is not None:
        try:
            target_date = datetime.strptime(args.date, "%Y-%m-%d").date()
        except ValueError:
            parser.error("--date must be YYYY-MM-DD")
    else:
        target_date = datetime.now(timezone.utc).date()
    started = datetime.now(timezone.utc)
    print(f"UID={os.getuid()} netns={os.readlink('/proc/self/ns/net')} "
          f"cgroup={Path('/proc/self/cgroup').read_text().splitlines()[0]} "
          f"Python={sys.version}", file=sys.stderr, flush=True)
    directory = ROOT / "data" / "trending"
    directory.mkdir(parents=True, exist_ok=True)
    state = directory / f".state-{target_date}.json"
    pages = json.loads(state.read_text(encoding="utf-8")) if state.exists() else {}
    if not state.exists():
        atomic_write(state, b"{}")
    rows = []
    requested = False
    for period in ("daily", "weekly"):
        for dimension in LANGUAGES:
            key = f"{period}/{dimension}"
            if key in pages:
                rows.extend(pages[key])
                print(f"{key}: {len(pages[key])} entries (resumed)", flush=True)
                continue
            if requested:
                time.sleep(random.uniform(2, 5))
            path = "" if dimension == "global" else "/" + dimension.lower()
            url = f"https://github.com/trending{path}?since={period}"
            html = fetch(url)
            requested = True
            captured = datetime.now(timezone.utc).isoformat(timespec="seconds")
            parser = TrendingParser()
            parser.feed(html)
            if not parser.rows:
                raise ValueError(f"No repositories parsed from {url}")
            entries = parser.rows[:25]
            for entry in entries:
                entry.update(fetched_at=captured, period=period, language_dimension=dimension)
            pages[key] = entries
            atomic_write(state, json.dumps(pages, ensure_ascii=False, separators=(",", ":")).encode("utf-8"))
            rows.extend(entries)
            print(f"{period}/{dimension}: {len(entries)} entries", flush=True)
    if args.date is None and datetime.now(timezone.utc).date() != started.date():
        raise RuntimeError("UTC date changed during fetch; no file written")
    content = "".join(json.dumps(row, ensure_ascii=False, separators=(",", ":")) + "\n" for row in rows).encode("utf-8")
    if len(content) >= 200_000:
        raise RuntimeError(f"Daily data is {len(content)} bytes, at or above 200 KB; no file written")
    output = directory / f"{target_date}.jsonl"
    atomic_write(output, content)
    state.unlink()
    print(f"Saved {len(rows)} entries from 10 lists to {output} ({len(content)} bytes)")


if __name__ == "__main__":
    main()
