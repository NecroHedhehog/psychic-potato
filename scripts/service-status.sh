#!/bin/bash

# проверяем состояние основных служб
# удобно чтобы быстро посмотреть что работает
# версия 1.0

echo "=== состояние служб ==="
echo $(date)
echo ""

# основные службы которые обычно должны работать
services=("ssh" "cron" "systemd-resolved" "NetworkManager")

echo "основные службы:"
for service in "${services[@]}"; do
    if systemctl is-active --quiet $service; then
        echo "$service: работает"
    else
        echo "$service: не активен"
    fi
done

echo ""

# TODO: добавить проверку nginx/apache если установлены

echo "проблемные службы:"
systemctl --failed --no-legend | head -5

echo ""

echo "последние 3 службы которые стартовали:"
journalctl -u "*.service" --since "1 hour ago" -n 3 --no-pager | grep "Started"

echo ""

echo "загруженных служб всего:" $(systemctl list-units --type=service | grep loaded | wc -l)
echo "активных:" $(systemctl list-units --type=service --state=active | wc -l)

echo ""
echo "проверка завершена"
