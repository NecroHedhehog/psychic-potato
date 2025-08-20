#!/bin/bash

# проверяем запланированные задачи cron
# важно знать что и когда автоматически запускается
# версия 1.0

echo "=== проверка cron задач ==="
echo $(date)
echo ""

# проверяем работает ли служба cron
echo "статус службы cron:"
systemctl is-active cron && echo "cron работает" || echo "cron не активен"
echo ""

# пользовательские cron задачи
echo "ваши cron задачи:"
crontab -l 2>/dev/null || echo "cron задач нет"
echo ""

# системные cron задачи
echo "системные cron файлы:"
if [ -d /etc/cron.d ]; then
    ls -la /etc/cron.d/ | grep -v "^total"
else
    echo "/etc/cron.d не найден"
fi
echo ""

# ежедневные задачи
echo "ежедневные задачи (/etc/cron.daily):"
if [ -d /etc/cron.daily ]; then
    ls -la /etc/cron.daily/ | grep -v "^total" | head -5
else
    echo "папка не найдена"
fi
echo ""

# TODO: добавить парсинг anacron

# последние выполненные задачи из логов
echo "последние выполненные cron задачи:"
journalctl -u cron --since "24 hours ago" -n 5 --no-pager 2>/dev/null | grep -v "^--" || echo "логи недоступны"
echo ""

# проверяем основной crontab файл
echo "основной crontab (/etc/crontab):"
if [ -f /etc/crontab ]; then
    cat /etc/crontab | grep -v "^#" | grep -v "^$"
else
    echo "файл не найден"
fi

echo ""

# время следующего запуска cron
echo "следующие задачи запустятся примерно каждый час"

echo ""
echo "проверка завершена"
