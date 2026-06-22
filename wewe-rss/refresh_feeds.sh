#!/usr/bin/env bash
# WeWe RSS 主动刷新脚本
# 用途：触发全部公众号「去微信读书重新抓取最新文章」（等同后台「立即更新」按钮），
#       等待抓取完成后，再输出各号最新条目数（复用 check_feeds.sh）。
# 为什么需要它：WeWe RSS 默认只在 CRON_EXPRESSION 指定时刻（如每天 5:35/17:35）才自动抓取，
#       平时直接 curl 读 .atom 只会拿到上次抓取的「历史缓存」。日报任务在读 RSS 前必须先跑本脚本，
#       才能保证读到的是最新文章，而不是几小时前的旧内容。
# 退出码：0=刷新并验证完成；1=容器/接口异常或触发刷新失败。
# 可被自动化任务或 cron 调用。

set -uo pipefail

PROJECT_DIR="/Users/lv/CodeBuddy/20260618102458/wechat-store-daily-news/wewe-rss"
BASE="http://localhost:4000"
MAX_WAIT=360          # 最多等待抓取完成的秒数（6 分钟）
SILENT_WINDOW=90      # 最近这么多秒内若无抓取活动，判定抓取已完成
MIN_WAIT=45           # 触发后至少等待的秒数，避免误判刚触发就完成

cd "$PROJECT_DIR" 2>/dev/null || { echo "[FATAL] 项目目录不存在: $PROJECT_DIR"; exit 1; }

echo "================ WeWe RSS 主动刷新 $(date '+%Y-%m-%d %H:%M:%S') ================"

# 0) 读取鉴权码（从 .env）
AUTH_CODE="$(grep -E '^AUTH_CODE=' .env 2>/dev/null | head -1 | cut -d= -f2-)"
if [ -z "${AUTH_CODE:-}" ]; then
  echo "[FATAL] 未在 .env 中找到 AUTH_CODE，无法触发刷新。"
  echo "RESULT=DOWN"
  exit 1
fi

# 1) 容器健康
if ! docker compose ps 2>/dev/null | grep -q "wewe-rss"; then
  echo "[动作] wewe-rss 容器未运行，尝试启动..."
  docker compose up -d >/dev/null 2>&1
  echo "[动作] 已执行 docker compose up -d，等待 15 秒..."
  sleep 15
fi

# 2) 接口连通
http_code=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/feeds/all.atom")
if [ "$http_code" != "200" ]; then
  echo "[异常] 后台接口不通 (HTTP $http_code)，请检查 Docker / 端口 4000。"
  echo "RESULT=DOWN"
  exit 1
fi
echo "[正常] 后台接口可访问 (HTTP 200)"

# 3) 触发全部公众号刷新（不带 mpId = 刷新全部）
echo "[动作] 触发全部公众号刷新（去微信读书拉取最新文章）..."
resp=$(curl -s -X POST "$BASE/trpc/feed.refreshArticles" \
  -H "Authorization: $AUTH_CODE" \
  -H "Content-Type: application/json" \
  -d '{"json":{}}' -w "|HTTP%{http_code}")
http="${resp##*|HTTP}"
body="${resp%|HTTP*}"
if [ "$http" != "200" ]; then
  echo "[异常] 触发刷新失败 (HTTP $http)：$body"
  echo "[提示] 常见原因：1) authCode 不正确；2) 微信读书账号登录态失效（需打开 $BASE 重新扫码）。"
  echo "RESULT=REFRESH_FAILED"
  exit 1
fi
echo "[OK] 已触发刷新，后台开始抓取（受 UPDATE_DELAY_TIME 限速，5 个号约需数分钟）。"

# 4) 轮询等待抓取完成：最近 SILENT_WINDOW 秒内无 getMpArticles 活动即视为完成
echo "[等待] 监测抓取活动，最多等待 $((MAX_WAIT/60)) 分钟..."
start=$(date +%s)
while :; do
  now=$(date +%s); elapsed=$((now-start))
  if [ "$elapsed" -ge "$MAX_WAIT" ]; then
    echo "[提示] 已达最长等待 ${MAX_WAIT}s，停止等待并继续。"
    break
  fi
  recent=$(docker compose logs --since "${SILENT_WINDOW}s" wewe-rss 2>&1 | grep -c 'getMpArticles')
  if [ "$elapsed" -ge "$MIN_WAIT" ] && [ "$recent" -eq 0 ]; then
    echo "[OK] 最近 ${SILENT_WINDOW}s 无抓取活动，判定刷新完成（已等待 ${elapsed}s）。"
    break
  fi
  sleep 20
done

# 5) 刷新后输出各号最新条目数（复用健康检查脚本）
echo ""
echo "================ 刷新后状态 ================"
if [ -x "$PROJECT_DIR/check_feeds.sh" ]; then
  bash "$PROJECT_DIR/check_feeds.sh"
else
  bash "$PROJECT_DIR/check_feeds.sh" 2>/dev/null || echo "[提示] 未找到 check_feeds.sh，跳过条目数汇总。"
fi
