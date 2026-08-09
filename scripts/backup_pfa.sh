#!/bin/bash
# PFA 亚宠展 DB 备份脚本
# 每次 booth 数据写入前必须执行
# 用法: bash scripts/backup_pfa.sh
set -e

BACKUP_DIR="/data/disk1/wwwroot/taf/backups"
DB_HOST="127.0.0.1"
DB_PORT="5432"
DB_NAME="taf"
DB_USER="postgres"
DB_PASS="R@De432!"

DATE=$(date +%Y%m%d_%H%M%S)
FILE="${BACKUP_DIR}/pfa_backup_${DATE}.sql"

mkdir -p "$BACKUP_DIR"

echo "=== PFA DB Backup: $DATE ==="
PGPASSWORD="$DB_PASS" pg_dump \
  -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
  --table='pfa_*' \
  --if-exists --clean --no-owner \
  > "$FILE"

echo "Backup: $(wc -c < "$FILE") bytes → $FILE"

# Keep last 7 backups
cd "$BACKUP_DIR"
ls -t pfa_backup_*.sql | tail -n +8 | xargs -r rm -f

echo "Kept $(ls pfa_backup_*.sql | wc -l) recent backups"
