#!/usr/bin/env bash
set -euo pipefail

TARGET="user:ou_8098f39866689778d045c07230a652f4"
ACCOUNT="main"
CHANNEL="feishu"
CITY="Shenzhen"

WEATHER_LINE=$(curl -fsS "wttr.in/${CITY}?format=3" || true)

if [[ -z "${WEATHER_LINE}" ]]; then
  MESSAGE=$'深圳今天天气\n暂时获取失败。请稍后手动查看，或等下次定时重试。'
else
  MESSAGE=$(printf '深圳今天天气\n%s\n出门前看一眼就够了。' "$WEATHER_LINE")
fi

MESSAGE=$(printf "%s" "$MESSAGE" | sed 's/[[:space:]]\+$//')

openclaw message send \
  --channel "$CHANNEL" \
  --account "$ACCOUNT" \
  --target "$TARGET" \
  --message "$MESSAGE"

mkdir -p "$HOME/.openclaw/logs"
printf '%s sent shenzhen weather\n' "$(date '+%Y-%m-%d %H:%M:%S')" >> "$HOME/.openclaw/logs/shenzhen-weather.log"
