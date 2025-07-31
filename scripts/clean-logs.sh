#!/bin/bash

# чистим старые логи чтобы освободить место
# иногда диск забивается полностью
# v1.2

echo "=== чистка логов ==="
echo $(date)
echo ""

# смотрим сколько места до чистки
echo "место до:"
df -h / | tail -1

echo ""

# чистим журналы systemd
echo "чистим systemd журналы..."
journalctl --vacuum-time=7d
echo "готово"

# старые .log файлы
echo ""
echo "ищем старые логи..."

# в системной папке если можем
find /var/log -name "*.log.*" -mtime +30 -delete
find /var/log -name "*.gz" -mtime +30 -delete
echo "системные логи почищены"

# в домашней папке тоже поищем
find ~ -name "*.log" -mtime +14 -delete
echo "пользовательские логи почищены"

# TODO: добавить очистку nginx/apache логов

echo ""
echo "место после:"
df -h / | tail -1

echo ""
echo "чистка завершена"
