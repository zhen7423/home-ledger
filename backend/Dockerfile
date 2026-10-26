# 家记后端镜像
#
# 采用「宿主机先构建 jar，镜像只装运行时」的方式，理由：
#   1. 不在容器内重复下载 Maven 依赖，构建快且可离线复现；
#   2. 镜像内不含 Maven 与源码，攻击面更小（需求 §5.2）；
#   3. 避开开发机对部分镜像仓库不可达的网络限制（需求 §6.5）。
#
# 构建前须在 backend/ 目录执行：./mvnw -DskipTests clean package
# jar 名随 pom 的 <version> 走（当前 1.0.0），升级版本时此处要同步改（第 33 轮登记）

FROM eclipse-temurin:25-jre-alpine

RUN addgroup -S app && adduser -S app -G app

WORKDIR /app

COPY target/backend-1.0.0.jar app.jar

# S10 档案照片目录（§4.3.1）：compose 把 uploads-data 卷挂到这里。容器以 app 用户跑，
# 命名卷首次挂载时若目标目录不存在，卷根会以 root 属主创建，app 用户随之写不进——
# 所以在镜像里先建好并把属主切给 app，Docker 首次挂载会把这个属主一并拷进新卷。
RUN mkdir -p /data/uploads && chown -R app:app /data/uploads

RUN chown -R app:app /app
USER app

EXPOSE 8080

ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75.0", "-jar", "/app/app.jar"]
