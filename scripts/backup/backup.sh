#!/usr/bin/env bash
# 家记每日备份（S10，需求 §4.1.6 / R6 / §12 S10）
#
# 备份两份东西，且**必须同一天成对**：
#   1. MySQL 逻辑备份（mysqldump，单文件）；
#   2. 档案照片目录（compose 里 app 与 nginx 共享的 uploads 目录）。
# 数据库与照片不是同一个事务，单独恢复任何一份都会得到一份与另一份对不上的数据；
# restore.sh 因此强制按「日期」成对恢复，不接受只恢复其一。
#
# 保留策略：31 天滚动（保留期比解散家庭的 30 天物理清除多一天）。
# §4.1.6 的清除是合规动作（用户解散满 30 天，数据应当删除），备份不阻挡它；
# 备份的职责是挡住「误删 / 磁盘损坏 / 半夜误操作」这类非用户本意的丢失，两者不冲突。
# 但也因此有一条明确的边界：**超过 31 天的备份会被清掉**，被清除家庭的数据不会借备份复活。
#
# 环境（默认 dev compose；生产见文末「生产用法」）：
#   COMPOSE_FILE   compose 文件路径        默认 $ROOT/deploy/docker-compose.yml
#   ENV_FILE       --env-file 用的口令文件   默认 $ROOT/deploy/.env
#   MYSQL_SERVICE  mysql 服务名             默认 mysql（生产 compose 是 mysql8）
#   UPLOADS_SOURCE 照片来源：以 / 开头 = 宿主机路径（生产 bind mount），
#                  否则 = docker 卷名（dev 命名卷）      默认 homeledger_uploads-data
#
# 生产用法示例（/opt/homeledger 部署，完整步骤见 docs/部署指南.md §4）：
#   COMPOSE_FILE=/opt/homeledger/deploy/prod/docker-compose.yml \
#   ENV_FILE=/opt/homeledger/deploy/prod/.env.prod \
#   MYSQL_SERVICE=mysql8 \
#   UPLOADS_SOURCE=/opt/homeledger/uploads \
#   BACKUP_DIR=/opt/homeledger/backups \
#   scripts/backup/backup.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT/deploy/.env}"
COMPOSE_FILE="${COMPOSE_FILE:-$ROOT/deploy/docker-compose.yml}"
MYSQL_SERVICE="${MYSQL_SERVICE:-mysql}"
UPLOADS_SOURCE="${UPLOADS_SOURCE:-homeledger_uploads-data}"
COMPOSE_ARGS=(--env-file "$ENV_FILE" -f "$COMPOSE_FILE")

BACKUP_DIR="${BACKUP_DIR:-$ROOT/backups}"
KEEP_DAYS="${KEEP_DAYS:-31}"

# 慢备份叠加运行只会互相踩产物（同秒时间戳互相覆盖、find 清理跑到一半）；
# flock 非阻塞拿锁，拿不到说明上一轮还没跑完，直接退出。
LOCK_FILE="${LOCK_FILE:-/tmp/homeledger-backup.lock}"
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "上一轮备份还在跑（$LOCK_FILE 被占用），本轮退出" >&2
  exit 0
fi

mkdir -p "$BACKUP_DIR"

DATE_STAMP="$(date +%Y%m%d-%H%M%S)"
DB_DUMP="$BACKUP_DIR/mysql-$DATE_STAMP.sql.gz"
UPLOADS_TAR="$BACKUP_DIR/uploads-$DATE_STAMP.tar.gz"

# 任一步失败就清掉本时间戳的两份产物：半截 dump 留在目录里会被 31 天滚动当成
# 好备份养着，restore 只查存在性不查完整性，真到恢复那天才发现灌不进去。
cleanup_on_failure() {
  rm -f -- "$DB_DUMP" "$UPLOADS_TAR"
}
trap cleanup_on_failure ERR

echo "==> 备份 MySQL（$MYSQL_SERVICE）=> $DB_DUMP"
# --no-tablespaces：非 root 账号在 MySQL 8.4 没有 PROCESS 权限时省掉 tablespace 告警；
# --single-transaction：InnoDB 一致性快照，不锁表；管道而非重定向，pipefail 才罩得住 gunzip 前的失败
docker compose "${COMPOSE_ARGS[@]}" exec -T "$MYSQL_SERVICE" sh -c \
  'exec mysqldump --single-transaction --routines --triggers --events --no-tablespaces --default-character-set=utf8mb4 -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"' \
  | gzip > "$DB_DUMP"
gzip -t "$DB_DUMP"

echo "==> 备份照片（$UPLOADS_SOURCE）=> $UPLOADS_TAR"
# 借 mysql 容器的镜像跑临时容器打包（镜像已在本地，不必再拉）：命名卷与宿主路径都按
# 绑定挂载处理——「-v 卷名:/data」与「-v 路径:/data」对 tar 是同一件事。
docker run --rm \
  -v "$UPLOADS_SOURCE":/data:ro \
  -v "$BACKUP_DIR":/backup \
  alpine:3.22 tar czf "/backup/$(basename "$UPLOADS_TAR")" -C /data .
gzip -t "$UPLOADS_TAR"

trap - ERR

echo "==> 清理 ${KEEP_DAYS} 天前的备份（按同一时间戳成对清）"
# mysql-*.sql.gz 与 uploads-*.tar.gz 共用同一时间戳，按时间戳批量删不会拆散一对；
# restore.sh 产出的 mysql-pre-restore-* 安全副本也匹配 mysql-*.sql.gz，同样参与滚动
find "$BACKUP_DIR" -maxdepth 1 -type f \
  \( -name 'mysql-*.sql.gz' -o -name 'uploads-*.tar.gz' \) \
  -mtime "+$((KEEP_DAYS - 1))" -delete

echo "==> 完成。当前备份清单："
ls -lh "$BACKUP_DIR" | tail -n +2

# 建议 crontab（每天 02:30，与后端 01:30 的物理清除任务错开；flock 防叠加）：
#   30 2 * * * cd /opt/homeledger && scripts/backup/backup.sh >> /var/log/homeledger-backup.log 2>&1
# 异地副本（R6）：把 BACKUP_DIR 同步到另一台机器或对象存储，例如：
#   rsync -a --delete /opt/homeledger/backups/ backup@offsite:/srv/homeledger-backups/
