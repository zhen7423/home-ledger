#!/usr/bin/env bash
# 家记恢复脚本（S10，需求 R6：恢复演练文档）
#
# 用法：restore.sh <时间戳，如 20260917-023000>
#   - 找 backups/ 下 mysql-<时间戳>.sql.gz 与 uploads-<时间戳>.tar.gz，两份必须都在；
#   - 先自动备份当前库（mysql-pre-restore-<现在>.sql.gz，恢复错了还能再恢复回来）；
#   - 停 app → 恢复 MySQL → 恢复照片 → 起app（中途还灌入时不接流量，半恢复状态不外泄）。
#
# 数据库恢复是「逐表替换」而不是「先清库」：mysqldump 生成的文件自带每张表的
# DROP TABLE IF EXISTS + CREATE TABLE，灌入时备份里有的表会被整体替换。
# 边界：备份里没有的表（如恢复目标库被人手工建过、或备份后又新增的表）不会被动到。
# 本脚本按「整库成对恢复」设计，且备份与库都来自同一套 Flyway 迁移，表集合一致，
# 正常运维下不存在残留表；恢复即意味着放弃当前库中被备份覆盖的那些表的全部数据。
#
# 环境变量与 backup.sh 同一套（COMPOSE_FILE / ENV_FILE / MYSQL_SERVICE / UPLOADS_SOURCE /
# BACKUP_DIR），生产用法示例见 backup.sh 头注释。

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT/deploy/.env}"
COMPOSE_FILE="${COMPOSE_FILE:-$ROOT/deploy/docker-compose.yml}"
MYSQL_SERVICE="${MYSQL_SERVICE:-mysql}"
UPLOADS_SOURCE="${UPLOADS_SOURCE:-homeledger_uploads-data}"
# dev compose 的 app 挂在 full profile 里，不带 profile 时 stop/restart app 会报「服务不存在」；
# prod 文件没有 profile，这个 flag 无副作用
COMPOSE_ARGS=(--env-file "$ENV_FILE" -f "$COMPOSE_FILE" --profile full)

BACKUP_DIR="${BACKUP_DIR:-$ROOT/backups}"

if [ "${1:-}" = "" ]; then
  echo "用法: $0 <时间戳>   例如: $0 20260917-023000" >&2
  echo "可用的时间戳：" >&2
  ls "$BACKUP_DIR" 2>/dev/null | sed -E 's/^(mysql|uploads)-([0-9]{8}-[0-9]{6})\.(sql|tar)\.gz$/\2/' | sort -u
  exit 1
fi
STAMP="$1"
DB_DUMP="$BACKUP_DIR/mysql-$STAMP.sql.gz"
UPLOADS_TAR="$BACKUP_DIR/uploads-$STAMP.tar.gz"

for f in "$DB_DUMP" "$UPLOADS_TAR"; do
  if [ ! -f "$f" ]; then
    echo "缺少备份文件: $f（恢复必须两份同时间戳成对，见 backup.sh）" >&2
    exit 1
  fi
done
gzip -t "$DB_DUMP" || { echo "备份文件损坏: $DB_DUMP" >&2; exit 1; }
gzip -t "$UPLOADS_TAR" || { echo "备份文件损坏: $UPLOADS_TAR" >&2; exit 1; }

echo "==> 目标：从 $STAMP 恢复（备份里含有的每张表都会被整体替换，未在其中列的表不受影响；回车继续 / Ctrl-C 取消）"
read -r -p "确认恢复？[y/N] " ANSWER
[ "$ANSWER" = "y" ] || { echo "已取消"; exit 1; }

# 压缩包先解开校验一遍（gzip CRC）：灌到一半才发现坏了，比一开始就拒绝糟糕得多
gunzip -t "$DB_DUMP"

PRE_STAMP="$(date +%Y%m%d-%H%M%S)"
PRE_DUMP="$BACKUP_DIR/mysql-pre-restore-$PRE_STAMP.sql.gz"
echo "==> 先备份当前库 => $PRE_DUMP（恢复错了还能从它再恢复回来）"
docker compose "${COMPOSE_ARGS[@]}" exec -T "$MYSQL_SERVICE" sh -c \
  'exec mysqldump --single-transaction --routines --triggers --events --no-tablespaces --default-character-set=utf8mb4 -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"' \
  | gzip > "$PRE_DUMP"

echo "==> 停后端（恢复期间不接流量）"
docker compose "${COMPOSE_ARGS[@]}" stop app

# 用管道而不是「< <(gunzip …)」：进程替换的退出码不参与 set -e，gz 中途损坏时
# mysql 拿着截断的 SQL 也可能 exit 0，库停在半恢复状态还打印 OK。
# 管道 + pipefail（已开）两边任何一环失败都当场停下。
echo "==> 恢复 MySQL（逐表替换：mysqldump 自带 DROP TABLE IF EXISTS）"
gunzip -c "$DB_DUMP" | docker compose "${COMPOSE_ARGS[@]}" exec -T "$MYSQL_SERVICE" sh -c \
  'exec mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"'

echo "==> 恢复照片卷（先清空再解包，避免删除过的照片借残留复活）"
# 整段 sh -c 用双引号：旧写法混排单双引号且结尾多一个单引号，bash -n 都过不了
# （本行在原脚本里就是坏的，恢复照片这一步从未跑通过）
docker run --rm \
  -v "$UPLOADS_SOURCE":/data \
  -v "$BACKUP_DIR":/backup \
  alpine:3.22 sh -c "rm -rf /data/* && tar xzf \"/backup/$(basename "$UPLOADS_TAR")\" -C /data"

echo "==> 重启后端：清掉进程内旧缓存与 Redis 里对不上的统计缓存"
docker compose "${COMPOSE_ARGS[@]}" start app

echo "==> 完成。用 /actuator/health 确认后端 UP，再打开 App 核对首页数据。"
