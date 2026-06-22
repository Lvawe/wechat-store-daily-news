#!/usr/bin/env bash
# 自动同步到 GitHub
# 用途：把 wechat-store-daily-news 目录下的新日报 / 改动自动提交并推送到 GitHub。
# 设计：可安全重复调用——没有改动时直接跳过，不会产生空提交；推送失败不影响日报本身已生成。
# 调用：bash wechat-store-daily-news/wewe-rss/sync_github.sh ["可选的提交说明"]
# 退出码：0=已推送或无改动；非0=提交/推送失败（日报文件仍在本地，可稍后手动 push）。

set -uo pipefail

# 仓库根目录 = 本脚本所在目录的上一级（wewe-rss 的父目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BRANCH="main"

cd "$REPO_DIR" 2>/dev/null || { echo "[FATAL] 仓库目录不存在: $REPO_DIR"; exit 1; }

echo "================ 同步到 GitHub $(date '+%Y-%m-%d %H:%M:%S') ================"

# 0) 确认是 git 仓库且已配置远程
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "[FATAL] $REPO_DIR 不是 git 仓库，无法同步。"
  exit 1
fi
if ! git remote get-url origin >/dev/null 2>&1; then
  echo "[FATAL] 未配置远程 origin，无法推送。"
  exit 1
fi

# 1) 安全校验：确保 .env 不会被提交（双保险）
if git ls-files --error-unmatch wewe-rss/.env >/dev/null 2>&1; then
  echo "[FATAL] 检测到 wewe-rss/.env 已被 git 跟踪！为防止密码泄露，已中止同步。"
  echo "[提示] 请执行：git rm --cached wewe-rss/.env  并确认 .gitignore 已排除它。"
  exit 1
fi

# 2) 暂存全部改动
git add -A

# 3) 没有改动则跳过，避免空提交
if git diff --cached --quiet; then
  echo "[跳过] 没有检测到改动，无需提交。"
  exit 0
fi

echo "[改动] 本次将提交以下文件："
git diff --cached --name-status

# 4) 提交（提交说明：优先用传入参数，否则用带时间戳的默认说明）
MSG="${1:-chore: 自动更新日报与改动 $(date '+%Y-%m-%d %H:%M')}"
git commit -q -m "$MSG"
echo "[提交] $(git log --oneline -1)"

# 5) 推送（SSH 鉴权，无需交互输入密码）
echo "[推送] 正在 push 到 origin/$BRANCH ..."
if git push -q origin "$BRANCH" 2>&1; then
  echo "[OK] 已推送到 GitHub。"
  echo "RESULT=PUSHED"
  exit 0
else
  echo "[异常] 推送失败。常见原因：网络不通、SSH key 失效、远程有新提交需先 pull。"
  echo "[提示] 改动已在本地提交，可稍后手动执行：git push origin $BRANCH"
  echo "RESULT=PUSH_FAILED"
  exit 1
fi
