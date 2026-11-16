#!/usr/bin/env bash
# 日报只读入口：过去 24h 死信数 + event_id；缺文件时输出 0，不写 state。
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/delivery-assurance.py" summary
