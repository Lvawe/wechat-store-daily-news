# 公众号 RSS 订阅链接清单

由 WeWe RSS 生成，已于 2026-06-18 验证全部可访问（HTTP 200）。
本机地址为 `http://localhost:4000`；如部署到服务器，请把 `localhost:4000` 换成实际地址。

| 公众号 | feed id | .atom 链接 |
|---|---|---|
| 微信小店助手 | `MP_WXS_3868829972` | http://localhost:4000/feeds/MP_WXS_3868829972.atom |
| 微信小店投放助手 | `MP_WXS_3909731516` | http://localhost:4000/feeds/MP_WXS_3909731516.atom |
| 腾讯营销 | `MP_WXS_2394733811` | http://localhost:4000/feeds/MP_WXS_2394733811.atom |
| 微信小店交易规则中心 | `MP_WXS_3947723193` | http://localhost:4000/feeds/MP_WXS_3947723193.atom |
| 微信视频创作安全中心 | `MP_WXS_3892687486` | http://localhost:4000/feeds/MP_WXS_3892687486.atom |
| （全部合并） | all | http://localhost:4000/feeds/all.atom |

## 说明
- `.atom` / `.rss` / `.json` 三种格式都支持，把后缀换掉即可。
- 进阶过滤参数：`?limit=30`、`?title_include=小店|新规`、`?title_exclude=招聘`、`?update=true`（手动触发更新）。
- 这些 /feeds 链接不需要 AUTH_CODE。
- 前提：本机 Docker 中的 wewe-rss 容器需保持运行（`docker compose up -d`）。
