#!/usr/bin/env python3
"""Independent T-047 acceptance calculation; does not import Tower implementation."""
import argparse
from datetime import datetime
import json
from pathlib import Path
import random
import re
import subprocess
from urllib.request import Request, build_opener, ProxyHandler

ROOT = Path(__file__).resolve().parents[2]
BOARD_HEAD = "1c819c6ea5c708687472c02f61c29a76c2f3dddd"
# Manually identified from BOARD diffs and delivery history, not Tower output.
CASES = {
    "T-023": ("78ce4ee360dec5f56a92b5cf04ef87f0aaa4f7f8", "a77a7f156b526ccc63add297d6d71fcce80bc975", "6dd2ec60ae609bacbaecb422b3550e774d7a9bbc", "node-2"),
    "T-005": ("42f5ae5e00c34947b0120673464407aeaf0d1805", "cd7823e089518bde0d0dc6aeda8fd7b52513d98f", "496b973c127522b7e226d7543154d2ff6fb86861", "node-1"),
    "T-028": ("785eac55a03814287318c2e42e73f94182537cb8", "fe441a51946f96dfae3d66f7def59a2a0ba2418a", "2589df58e97e2371afba373600c6174ab5a2683b", "node-1"),
}


def git(*args):
    return subprocess.check_output(["git", "-C", str(ROOT), *args], text=True).strip()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", default="http://127.0.0.1:8000")
    parser.add_argument("--key-file", default="/home/hatch/workspace/muse-control-tower/runtime/ct_access_key.txt")
    parser.add_argument("--receipts", default="/home/hatch/hooks/state/muse-hub/receipts")
    args = parser.parse_args()
    board = git("show", BOARD_HEAD + ":BOARD.md")
    completed = [m[1] for line in board.splitlines()
                 if (m := re.match(r"\| (T-\d+) \|.*?\|[^|]*\| 完成 \|", line))]
    selected = random.Random(47).sample(sorted(completed), 3)
    assert selected == list(CASES), selected
    print(json.dumps({"board_head": BOARD_HEAD, "completed": len(completed), "seed": 47, "sample": selected}, ensure_ascii=False))
    key = Path(args.key_file).read_text().strip()
    opener = build_opener(ProxyHandler({}))
    checks = []
    for task, (dispatch, first, accept, node) in CASES.items():
        stamps = []
        for sha in (dispatch, first, accept):
            print("$ git show -s --format='%H %cI %s' " + sha)
            print(git("show", "-s", "--format=%H %cI %s", sha))
            stamps.append(datetime.fromisoformat(git("show", "-s", "--format=%cI", sha)))
        for sha in (dispatch, accept):
            print("$ git show --format= --unified=0 " + sha + " -- BOARD.md  # task row only")
            print("\n".join(line for line in git("show", "--format=", "--unified=0", sha, "--", "BOARD.md").splitlines()
                            if re.match(r"^[+-]\| " + task + r" \|", line)))
        print("$ git log --no-merges --format='%H %cI %s' " + BOARD_HEAD + " -- results/" + node + "/" + task + "*")
        print(git("log", "--no-merges", "--format=%H %cI %s", BOARD_HEAD, "--", "results/" + node + "/" + task + "*"))
        # Each of these samples has exactly one worker delivery. T-005's director
        # typo correction is explicitly excluded, despite touching the result file.
        deliveries = git("log", "--no-merges", "--format=%H %s", BOARD_HEAD, "--", "results/" + node + "/" + task + "*").splitlines()
        worker = [line for line in deliveries if "【总控】" not in line]
        assert len(worker) == 1 and worker[0].startswith(first)
        rows = git("log", "--first-parent", "--format=", "-p", BOARD_HEAD, "--", "BOARD.md").splitlines()
        board_rejects = [line for line in rows if re.match(r"^\+\| " + task + r" \|", line) and "| 拒收 |" in line]
        receipts = [json.loads(p.read_text()) for p in sorted(Path(args.receipts).glob("*.json"))]
        receipts = [r for r in receipts if r.get("task_id") == task and r.get("node_id") in (None, node)]
        print("receipt metadata:", json.dumps([{k:r.get(k) for k in ("task_id", "node_id", "version_sha", "verdict", "reviewed_at")} for r in receipts], ensure_ascii=False))
        assert not board_rejects and not any(r.get("verdict") == "REJECT" for r in receipts)
        d, f, a = stamps
        expected = {"dispatch_to_first_commit_seconds": int((f-d).total_seconds()),
                    "commit_to_acceptance_seconds": int((a-f).total_seconds()),
                    "total_seconds": int((a-d).total_seconds()), "delivery_commit_count": 1, "rejection_count": 0}
        request = Request(args.base + "/api/v1/tasks/" + task, headers={"X-CT-Access-Key": key})
        with opener.open(request, timeout=180) as response:
            assert response.status == 200
            telemetry = json.load(response)["telemetry"]
        actual = {k:telemetry[k] for k in expected}
        assert actual == expected, (task, expected, actual)
        assert telemetry["quota_used"] is None and telemetry["quota_status"] == "未采集"
        differences = {k: actual[k] - value for k, value in expected.items()}
        print("hand arithmetic / API / differences:", json.dumps({"task":task,"hand":expected,"api":actual,"differences":differences},ensure_ascii=False))
        print("Tower telemetry:", json.dumps(telemetry, ensure_ascii=False))
        checks.append({"task_id":task,"manual":expected,"tower":telemetry,"difference":differences})
    print("PASS: 3/3, exact seconds and counts; each minute rounding error <= 30 seconds")
    (Path(__file__).parent / "comparison.json").write_text(json.dumps(checks,ensure_ascii=False,indent=2) + "\n")


if __name__ == "__main__":
    main()
