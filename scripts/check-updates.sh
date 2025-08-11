#!/bin/bash

# проверяем есть ли обновления для системы
# версия 1.0

echo "=== проверка обновлений ==="
echo "время:" $(date)
echo ""

# обновляем список пакетов
echo "обновляем список пакетов..."
apt update > /dev/null 2>&1

# проверяем сколько обновлений доступно
UPDATES=$(apt list --upgradable 2>/dev/null | grep -c upgradable)

if [ $UPDATES -gt 1 ]; then
    echo "доступно обновлений:" $((UPDATES-1))
    echo ""
    
    echo "список пакетов для обновления:"
    apt list --upgradable 2>/dev/null | grep upgradable | head -10
    echo ""
else
    echo "система актуальна, обновлений нет"
    echo ""
fi

# проверяем безопасные обновления отдельно
SECURITY=$(apt list --upgradable 2>/dev/null | grep -i security | wc -l)
if [ $SECURITY -gt 0 ]; then
    echo "ВНИМАНИЕ: есть обновления безопасности:" $SECURITY
    echo ""
fi

# TODO: добавить автоматическую установку безопасных обновлений

# проверяем когда последний раз обновлялись
echo "последнее обновление пакетов:"
ls -la /var/cache/apt/pkgcache.bin 2>/dev/null | awk '{print $6, $7, $8}' || echo "информация недоступна"

echo ""

# версия системы
echo "текущая версия системы:"
lsb_release -d | cut -f2

echo ""
echo "проверка завершена"
