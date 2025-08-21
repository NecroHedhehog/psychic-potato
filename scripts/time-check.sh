#!/bin/bash

# проверяем время системы и синхронизацию
# важно чтобы время было правильное особенно на серверах
# версия 1.0

echo "=== проверка времени ==="
echo $(date)
echo ""

# текущее время системы
echo "системное время:"
date
echo "время в UTC:" $(date -u)
echo ""

# часовой пояс
echo "часовой пояс:"
timedatectl show --property=Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null || echo "не определён"
echo ""

# статус NTP синхронизации
echo "NTP синхронизация:"
if command -v timedatectl > /dev/null; then
    timedatectl status | grep "NTP service"
    timedatectl status | grep "NTP synchronized"
else
    echo "timedatectl недоступен"
fi
echo ""

# проверяем службы времени
echo "службы синхронизации времени:"
systemctl is-active systemd-timesyncd 2>/dev/null && echo "systemd-timesyncd: активен" || echo "systemd-timesyncd: неактивен"
systemctl is-active ntp 2>/dev/null && echo "ntp: активен" || echo "ntp: неактивен" 
systemctl is-active chronyd 2>/dev/null && echo "chronyd: активен" || echo "chronyd: неактивен"
echo ""

# TODO: добавить проверку drift времени

# NTP серверы
echo "NTP серверы:"
if [ -f /etc/systemd/timesyncd.conf ]; then
    grep "^NTP=" /etc/systemd/timesyncd.conf 2>/dev/null || echo "не настроены в timesyncd.conf"
elif [ -f /etc/ntp.conf ]; then
    grep "^server" /etc/ntp.conf | head -3
else
    echo "конфигурационные файлы не найдены"
fi
echo ""

# uptime системы
echo "система работает:"
uptime -p

echo ""

# последняя синхронизация (если доступно)
echo "последняя синхронизация времени:"
journalctl -u systemd-timesyncd --since "1 day ago" -n 1 --no-pager 2>/dev/null | tail -1 || echo "информация недоступна"

echo ""
echo "проверка завершена"
