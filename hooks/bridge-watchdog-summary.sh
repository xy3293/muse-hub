#!/usr/bin/env bash
# 桥与看门狗日报小节（供总控 14:10 日报引用）
# 输出：过去 24h 的 alert/recover 条数、最长未恢复时长、当前三台桥状态。
# 只读：不写 state、不改 alerts/、不发 Issue。
set -euo pipefail
STATE_DIR="${MUSE_HUB_STATE_DIR:-$HOME/hooks/state/muse-hub}"
EVENTS_DIR="$STATE_DIR/events"
NOW_EPOCH="$(date +%s)"
DAY_AGO=$((NOW_EPOCH - 86400))

count_24h() {
  local kind="$1" n=0 f det epoch
  for f in "$EVENTS_DIR"/"$kind"-*.json; do
    [[ -f "$f" ]] || continue
    if [[ "$kind" == "bridge_alert" ]]; then
      det="$(jq -r '.alert.detected_at // .timestamps.detected_at // empty' "$f" 2>/dev/null)" || det=""
    else
      det="$(jq -r '.recover.recovered_at // .timestamps.detected_at // empty' "$f" 2>/dev/null)" || det=""
    fi
    [[ -n "$det" ]] || continue
    epoch="$(date -d "$det" +%s 2>/dev/null)" || continue
    if [[ "$epoch" -ge "$DAY_AGO" ]]; then
      n=$((n + 1))
    fi
  done
  printf '%s' "$n"
}

longest_unrecovered_mins() {
  local best=0 f st det epoch dur
  for f in "$EVENTS_DIR"/bridge_alert-*.json; do
    [[ -f "$f" ]] || continue
    st="$(jq -r '.state // empty' "$f" 2>/dev/null)" || st=""
    [[ "$st" == "DETECTED" ]] || continue
    det="$(jq -r '.alert.detected_at // .timestamps.detected_at // empty' "$f" 2>/dev/null)" || det=""
    [[ -n "$det" ]] || continue
    epoch="$(date -d "$det" +%s 2>/dev/null)" || continue
    dur=$(( (NOW_EPOCH - epoch) / 60 ))
    if [[ "$dur" -gt "$best" ]]; then
      best="$dur"
    fi
  done
  printf '%s' "$best"
}

bridge_status() {
  local port="$1" name="$2" proxy resp ok logged needs
  proxy="${HTTPS_PROXY%:*}:3130"
  resp="$(curl -s --proxy "$proxy" --max-time 8 "http://100.118.194.61:$port/health" 2>/dev/null)" || resp=""
  if [[ -z "$resp" ]]; then
    printf '%s: DOWN' "$name"
    return 0
  fi
  ok="$(printf '%s' "$resp" | jq -r '.ok // false' 2>/dev/null)" || ok="false"
  logged="$(printf '%s' "$resp" | jq -r '.loggedIn // false' 2>/dev/null)" || logged="false"
  needs="$(printf '%s' "$resp" | jq -r '.needsApproval // false' 2>/dev/null)" || needs="false"
  if [[ "$ok" == "true" && "$logged" == "true" ]]; then
    if [[ "$needs" == "true" ]]; then
      printf '%s: ok/已登录/有待批卡' "$name"
    else
      printf '%s: ok/已登录' "$name"
    fi
  else
    printf '%s: 异常(ok=%s,loggedIn=%s)' "$name" "$ok" "$logged"
  fi
}

alerts_24h="$(count_24h bridge_alert)"
recovers_24h="$(count_24h bridge_recover)"
longest="$(longest_unrecovered_mins)"
b3="$(bridge_status 8787 node-3)"
b1="$(bridge_status 8788 node-1)"
b2="$(bridge_status 8789 node-2)"

printf '桥与看门狗(过去24h): alert %s 条, recover %s 条; 最长未恢复 %s 分钟; 当前: %s, %s, %s\n' "$alerts_24h" "$recovers_24h" "$longest" "$b3" "$b1" "$b2"
bash "$(dirname -- "${BASH_SOURCE[0]}")/dead-letter-summary.sh"
