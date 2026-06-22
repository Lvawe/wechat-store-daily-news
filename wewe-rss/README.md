# WeWe RSS 部署与公众号订阅指南

把微信公众号转成稳定的 RSS 订阅链接，供「微信小店资讯日报」自动化任务直接读取，替代不稳定的 web 搜索。

- 项目：[cooderl/wewe-rss](https://github.com/cooderl/wewe-rss)（v2.6.1，已归档但可用）
- 原理：基于**微信读书**接口抓取公众号文章并生成 RSS
- 本目录提供：MySQL 版 `docker-compose.yml`（推荐）、SQLite 版 `docker-compose.sqlite.yml`、环境变量模板 `.env.example`

---

## 一、快速部署（MySQL 版，推荐）

> 前置条件：已安装 Docker 与 Docker Compose。

```bash
# 1. 进入本目录
cd wechat-store-daily-news/wewe-rss

# 2. 生成环境变量文件并修改（至少改 AUTH_CODE 和 DB_ROOT_PASSWORD）
cp .env.example .env
#   用编辑器打开 .env，把 AUTH_CODE 改成你自己的私密值

# 3. 启动（首次会拉取镜像 + 初始化数据库，稍等 30~60 秒）
docker compose up -d

# 4. 查看状态 / 日志
docker compose ps
docker compose logs -f wewe-rss
```

启动成功后，浏览器打开后台：

```
http://localhost:4000
```

输入 `.env` 里设置的 `AUTH_CODE` 登录。

### SQLite 版（更轻量，免数据库容器）

```bash
cd wechat-store-daily-news/wewe-rss
cp .env.example .env       # 仍需改 AUTH_CODE
docker compose -f docker-compose.sqlite.yml up -d
```

---

## 二、绑定微信读书账号（关键第一步）

WeWe RSS 靠微信读书账号去拉公众号内容，必须先绑定。

1. 后台左侧进入 **「账号管理」 → 「添加账号」**
2. 用**微信扫码登录你的微信读书账号**
3. ⚠️ 扫码时**不要勾选「24 小时后自动退出」**，否则一天后失效要重新登录

> 账号状态说明：
> - **今日小黑屋**：被风控了，等 24 小时自动恢复；正常时可重启容器清除记录
> - **失效**：登录态过期，需重新扫码

---

## 三、搜索并订阅这 5 个公众号

WeWe RSS 通过**公众号文章分享链接**来添加订阅（不是直接搜名字），步骤如下：

### 1. 拿到每个公众号的一篇文章分享链接

对下面每个公众号，各做一次：
1. 微信里打开该公众号 → 进任意一篇推文
2. 右上角 **「…」 → 「复制链接」**
3. 得到形如 `https://mp.weixin.qq.com/s?__biz=xxx&mid=xxx&idx=1&sn=xxx` 的链接

需要订阅的 5 个公众号：

| 序号 | 公众号名称 |
|---|---|
| 1 | 微信小店助手 |
| 2 | 微信小店投放助手 |
| 3 | 腾讯营销 |
| 4 | 微信小店交易规则中心 |
| 5 | 微信视频创作安全中心 |

### 2. 在后台添加订阅

1. 后台进入 **「公众号源」 → 「添加」**
2. 把上一步复制的**文章分享链接**粘进去 → 提交
3. WeWe RSS 会自动解析出该公众号，并开始抓取其历史与最新文章
4. 重复 5 次，把 5 个公众号都加上

> ⚠️ **添加频率别太快**：一次加完 5 个容易触发风控。建议每加 1 个间隔几分钟；若提示被封控，等 24 小时再继续。

---

## 四、获取 RSS 订阅链接

订阅成功后，每个公众号源都会有独立的 feed id（形如 `MP_WXS_xxxx`）。链接格式：

```
# 单个公众号（三种格式任选）
http://localhost:4000/feeds/MP_WXS_xxxx.atom
http://localhost:4000/feeds/MP_WXS_xxxx.rss
http://localhost:4000/feeds/MP_WXS_xxxx.json

# 全部订阅合并成一个
http://localhost:4000/feeds/all.atom
```

> - `/feeds` 链接**不需要 AUTH_CODE**，可直接被自动化任务抓取
> - 部署到服务器时，把 `localhost:4000` 换成 `.env` 里的 `SERVER_ORIGIN_URL`
> - 进阶过滤：`?limit=30`、`?title_include=小店|新规`、`?title_exclude=招聘` 等

在后台「公众号源」列表里，点对应公众号即可看到/复制它的 feed 链接。

---

## 五、把 RSS 链接接入自动化任务

拿到 5 个公众号的 RSS 链接后，发给我，我会把「微信小店资讯日报」自动化任务的 prompt 改成**直接 `web_fetch` 读这些 RSS**，替代现在的 web 搜索，时效性和完整性会显著提升。

建议整理成这样发给我：

```
微信小店助手：        http://你的地址/feeds/MP_WXS_aaaa.atom
微信小店投放助手：    http://你的地址/feeds/MP_WXS_bbbb.atom
腾讯营销：            http://你的地址/feeds/MP_WXS_cccc.atom
微信小店交易规则中心：http://你的地址/feeds/MP_WXS_dddd.atom
微信视频创作安全中心：http://你的地址/feeds/MP_WXS_eeee.atom
```

---

## 六、常用运维命令

```bash
docker compose ps                 # 查看运行状态
docker compose logs -f wewe-rss   # 实时日志
docker compose restart wewe-rss   # 重启（可清账号小黑屋记录）
docker compose down               # 停止并移除容器（数据卷保留）
docker compose pull && docker compose up -d   # 升级镜像
```

---

## 七、风险与注意

- 本工具依赖微信读书接口，**频繁操作可能导致账号被临时封控**（小黑屋），等 24 小时即可。
- 部分请求会经官方中转域名 `weread.111965.xyz`（国内可用 `weread.965111.xyz`），作者声明不存数据，介意者可关注其开源代码自行评估。
- 建议**单独用一个微信读书小号**绑定，避免影响常用账号。
- 公网部署务必设置强 `AUTH_CODE`，必要时加反向代理 + HTTPS。
