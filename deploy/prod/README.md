# 生产部署专用文件

本目录是自托管生产环境（Docker Compose）所需的最小文件集：

| 文件 | 用途 |
| --- | --- |
| `docker-compose.yml` | MySQL 8.4 + 后端容器编排（按 2C2G 机型调过内存参数） |
| `nginx-homeledger.conf` | 宿主机 Nginx 站点配置（复用已有 Nginx 时用） |
| `.env.prod.example` | 环境变量模板，复制为 `.env.prod` 后填写 |

完整部署步骤（含服务器前置结论、MySQL 8.4 并存、Nginx 接入、APK 打包签名、备份恢复、
HTTPS、升级与常见问题）见 [docs/部署指南.md](../../docs/部署指南.md)。
