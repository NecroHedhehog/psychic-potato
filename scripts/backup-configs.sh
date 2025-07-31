#!/bin/bash

# делаем бэкап конфигов
# чтобы случайно не потерять настройки
# версия 1.0

BACKUP_DIR="/tmp/backup-$(date +%Y%m%d)"
ARCHIVE_NAME="configs-$(date +%Y%m%d).tar.gz"

echo "=== бэкап файлов ==="
echo "папка:" $BACKUP_DIR
echo ""

mkdir $BACKUP_DIR

echo "копируем файлы..."

# системные конфиги
cp /etc/hostname $BACKUP_DIR/
cp /etc/hosts $BACKUP_DIR/
cp /etc/resolv.conf $BACKUP_DIR/

echo "системные - ok"

# пользовательские
cp ~/.bashrc $BACKUP_DIR/bashrc
cp ~/.profile $BACKUP_DIR/profile

echo "пользовательские - ok"

# TODO: добавить ssh конфиги

echo ""
echo "делаем архив..."
cd /tmp
tar -czf $ARCHIVE_NAME $(basename $BACKUP_DIR)

echo "готово:" $ARCHIVE_NAME
echo "размер:" $(ls -lh $ARCHIVE_NAME | awk '{print $5}')

# чистим временную папку
rm -rf $BACKUP_DIR

echo ""
echo "бэкап сделан"
