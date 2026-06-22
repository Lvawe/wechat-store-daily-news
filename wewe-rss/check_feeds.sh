#!/usr/bin/env bash
# WeWe RSS 健康检查脚本
# 用途：检查 5 个公众号 RSS 是否正常有内容，输出健康报告。
# 退出码：0=全部正常；1=有异常（容器没起/接口不通/有空源）。
# 可被自动化任务或 cron 调用，根据退出码与输出决定是否提醒。

set -uo pipefail

PROJECT_DIR="/Users/lv/CodeBuddy/20260618102458/wechat-store-daily-news/wewe-rss"
BASE="http://localhost:4000"

# 公众号清单： feedId|名称
FEEDS=(
  "MP_WXS_3868829972|微信小店助手"
  "MP_WXS_3909731516|微信小店投放助手"
  "MP_WXS_2394733811|腾讯营销"
  "MP_WXS_3947723193|微信小店交易规则中心"
  "MP_WXS_3892687486|微信视频创作安全中心"
)

cd "$PROJECT_DIR" 2>/dev/null || { echo "[FATAL] 项目目录不存在: $PROJECT_DIR"; exit 1; }

echo "================ WeWe RSS 健康检查 $(date '+%Y-%m-%d %H:%M:%S') ================"

# 1) 容器健康
if ! docker compose ps 2>/dev/null | grep -q "wewe-rss"; then
  echo "[异常] wewe-rss 容器未运行，尝试启动..."
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
echo "------------------------------------------------------------------"

# 3) 逐个检查 feed 条目数
empty_list=()
ok_count=0
for item in "${FEEDS[@]}"; do
  id="${item%%|*}"
  name="${item##*|}"
  entries=$(curl -s "$BASE/feeds/$id.atom" | grep -c '<entry>')
  if [ "$entries" -gt 0 ]; then
    printf "  [OK]   %-22s %s 条\n" "$name" "$entries"
    ok_count=$((ok_count+1))
  else
    printf "  [空!]  %-22s 0 条（疑似微信读书登录态失效/未收录）\n" "$name"
    empty_list+=("$name")
  fi
done

echo "------------------------------------------------------------------"
if [ "${#empty_list[@]}" -eq 0 ]; then
  echo "[结论] 全部 $ok_count 个公众号 RSS 正常。"
  echo "RESULT=HEALTHY"
  exit 0
else
  echo "[结论] 有 ${#empty_list[@]} 个公众号 RSS 为空：${empty_list[*]}"
  echo "[建议] 1) 打开 http://localhost:4000 → 账号管理，确认微信读书账号是否「失效」，失效则重新扫码；"
  echo "        2) 若账号正常仍为空，多为微信读书未收录该号，日报对该号改用 web 搜索兜底。"
  echo "RESULT=DEGRADED"
  echo "EMPTY_FEEDS=${empty_list[*]}"
  exit 1
fi
