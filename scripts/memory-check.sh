#!/bin/bash

# подробно смотрим как используется память
# когда система тормозит часто дело в нехватке RAM
# версия 1.0

echo "=== проверка памяти ==="
echo $(date)
echo ""

# основная информация о памяти
echo "использование памяти:"
free -h
echo ""

# более детальная разбивка
echo "детально:"
cat /proc/meminfo | head -10
echo ""

# проверяем swap
echo "файл подкачки:"
swapon --show 2>/dev/null || echo "swap не настроен"
echo ""

# топ процессов по памяти (более детально чем в process-monitor)
echo "больше всего памяти используют:"
ps aux --sort=-%mem | head -8 | awk '{printf "%-12s %6s %6s %s\n", $1, $4"%", $6"KB", $11}'
echo ""

# TODO: добавить проверку memory leaks

# проверяем есть ли проблемы с памятью в логах
echo "ошибки памяти в логах:"
dmesg | grep -i "out of memory\|killed process" | tail -3 || echo "ошибок не найдено"
echo ""

# статистика по типам памяти
echo "доступная память:"
awk '/MemAvailable/ {printf "доступно: %.1f GB\n", $2/1024/1024}' /proc/meminfo

# процент использования
MEM_USED=$(free | grep Mem | awk '{printf "%.0f", ($3/$2)*100}')
echo "использовано: $MEM_USED%"

echo ""
echo "проверка завершена"
