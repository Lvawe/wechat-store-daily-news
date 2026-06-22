# 微信小店资讯日报（wechat-store-daily-news）

一套用于**自动汇总微信小店生态资讯**的工具集：基于本机 WeWe RSS 把 5 个微信公众号转成稳定的 RSS 订阅，配合主动刷新 / 健康检查脚本，每日生成「微信小店资讯日报」。

## 目录结构

```
wechat-store-daily-news/
├── reports/                       # 每日生成的资讯日报（Markdown）
│   └── 微信小店资讯日报-YYYY-MM-DD-HHmm.md
└── wewe-rss/                      # WeWe RSS 部署与运维
    ├── docker-compose.yml         # MySQL 版（推荐）
    ├── docker-compose.sqlite.yml  # SQLite 版（更轻量）
    ├── .env.example               # 环境变量模板（复制为 .env 后填写）
    ├── feeds.md                   # 5 个公众号的 RSS feed 链接清单
    ├── refresh_feeds.sh           # 主动触发刷新：让 RSS 去微信读书拉最新文章
    ├── check_feeds.sh             # 健康检查：体检容器/接口/各号条目数
    ├── README.md                  # WeWe RSS 部署与订阅详细指南
    └── STABILITY.md               # 稳定性运维手册（账号失效成因与恢复流程）
```

## 核心机制

WeWe RSS 借**微信读书**接口抓取公众号文章，默认只在固定时刻（cron）抓取，平时直接读 `.atom` 只能拿到历史缓存。因此本项目提供：

- **`refresh_feeds.sh`**：读 RSS 前主动触发「立即更新」，确保拿到最新文章而非旧缓存；自动确保容器运行 → 触发刷新 → 智能等待抓取完成 → 输出体检结果。
- **`check_feeds.sh`**：一条命令体检 5 个公众号，输出 `HEALTHY` / `DEGRADED` / `DOWN` 结论。
- 当某个公众号 RSS 为空（多为微信读书登录态临时失效）时，日报任务会自动用 web 搜索兜底，并在报告中标注。

## 快速开始

```bash
cd wewe-rss
cp .env.example .env          # 填写 AUTH_CODE 和 DB_ROOT_PASSWORD
docker compose up -d          # 启动（MySQL 版）
bash refresh_feeds.sh         # 主动刷新并体检
```

详见 [`wewe-rss/README.md`](wewe-rss/README.md)。

## 监控的 5 个公众号

微信小店助手、微信小店投放助手、腾讯营销、微信小店交易规则中心、微信视频创作安全中心。

## 安全说明

- `wewe-rss/.env` 含 `AUTH_CODE` 与数据库密码，**已被 `.gitignore` 排除，不会上传**。请勿手动提交。
- 公网部署务必设置强 `AUTH_CODE`，并配合反向代理 + HTTPS。
