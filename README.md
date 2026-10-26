# 家记（homeledger）

单个家庭自托管的生活记录应用：记账、猫咪、宝宝、提醒。Flutter 客户端 +
Spring Boot 后端 + Docker Compose，数据完全部署在自己手里，全家共用一个空间。

## 功能

- **模块可定制**：记账 / 宝宝 / 猫咪三个模块可按需开关，底部 Tab 顺序可拖拽调整，偏好按账号持久化
- **记账**：两级类别与多支付方式，三维度预算（总额/大类/成员），周期记账自动生成流水，统计五图与自定义区间，导出 xlsx / csv
- **猫咪**：多猫档案，驱虫周期与到期倒计时，猫粮袋时间线与消耗推算（日均、月度趋势、品牌占比）
- **宝宝**：身高体重与 WS/T 423-2022 百分位曲线，疫苗应种清单（内置国家免疫规划 2026 版程序表，自费项手动补录，计划日期可自设），奶粉罐时间线与消耗推算，里程碑与就诊记录
- **提醒**：预算超支/预警、驱虫到期、疫苗逾期与临近，走本地通知，点开直达对应列表
- **家庭**：邀请码加入，创建者/成员两级角色，解散后 30 天物理清除
- **安全**：JWT 双令牌与令牌版本吊销，IP + 账号双维度限流，全表 family_id 租户隔离

## 技术栈

| 层 | 选型 |
| --- | --- |
| 客户端 | Flutter 3.47，Riverpod、GoRouter、dio、freezed |
| 后端 | Java 25、Spring Boot 4.1、Spring Security、MyBatis-Plus、Flyway |
| 存储 | MySQL 8.4、Redis（限流 / 统计缓存 / 刷新令牌） |
| 部署 | Docker Compose、Nginx（照片经 X-Accel-Redirect internal 直出） |

## 快速开始（本地开发）

```bash
# 1. 基础设施（首次先 cp deploy/.env.example deploy/.env 并填 JWT_SECRET）
docker compose --env-file deploy/.env -f deploy/docker-compose.yml up -d mysql redis

# 2. 后端
cd backend
export DB_PORT=13306 DB_PASSWORD=homeledger_dev_pwd REDIS_PORT=16379 \
       REDIS_PASSWORD=redis_dev_pwd JWT_SECRET=<32 字节 Base64>
./mvnw spring-boot:run        # http://localhost:8080

# 3. 客户端
cd app
flutter pub get
flutter run                   # 默认基址 http://10.0.2.2:18088（Android 模拟器 → 宿主机）
```

`JWT_SECRET` 生成：`node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"`

## 目录结构

```
app/           Flutter 客户端（MVVM：ui/features/{模块}/views + view_models，data/repositories）
backend/       Spring Boot 后端（controller/service/mapper，Flyway 迁移，租户拦截器）
deploy/        docker-compose（dev 全栈 / prod 复用宿主服务两套编排）、nginx 配置、环境变量样例
scripts/       backup/（数据库与照片的备份恢复脚本）
docs/          部署指南、UI 设计语言规范
```

## 文档

- [部署指南](docs/部署指南.md) —— 本地开发、生产自托管、APK 打包签名、备份恢复、HTTPS、升级、FAQ
- [UI 设计语言规范](docs/UI设计语言规范-暖居.md) —— 配色、字阶、圆角与组件间距的取值依据

## 测试

```bash
cd backend && ./mvnw -o verify     # 集成测试依赖 docker 里的真实 MySQL/Redis
cd app && dart analyze && flutter test
```

## 安全说明

- 生产默认纯 HTTP 是登记在案的待办，对外服务前请按[部署指南 §5](docs/部署指南.md)接 TLS；
- 仓库内唯一的密钥值是测试专用的 JWT secret（`backend/src/test/resources`），只作用于
  集成测试，与任何部署环境无关；生产密钥一律从环境变量注入；
- 客户端 release 构建必须携带 `--dart-define=API_BASE_URL`，缺省会启动即报错而不是静默连模拟器地址。

## 数据来源与免责声明

疫苗免疫程序转录自《国家免疫规划疫苗儿童免疫程序及说明（2026 年版）》，生长曲线标准
转录自 WS/T 423-2022《7 岁以下儿童生长标准》附录 A。两份标准原文有版权限制，不随本仓库
分发，请通过官方渠道获取。App 内的曲线与应种清单仅供参考，不作为医学诊断或接种依据，
请遵医嘱。

## 许可

[MIT](LICENSE)
