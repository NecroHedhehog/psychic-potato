#!/bin/bash

# показываем какие папки сколько места занимают
# полезно когда нужно понять куда девается место на диске
# версия 1.0

echo "=== анализ использования диска ==="
echo "время:" $(date)
echo ""

# общее состояние дисков
echo "состояние файловых систем:"
df -h | grep -v tmpfs
echo ""

# топ папок в корне по размеру
echo "самые большие папки в корне:"
du -h --max-depth=1 / 2>/dev/null | sort -hr | head -8
echo ""

# что занимает место в /home
echo "использование /home:"
if [ -d /home ]; then
    du -h --max-depth=2 /home 2>/dev/null | sort -hr | head -5
else
    echo "/home не найден"
fi
echo ""

# проверяем /var где обычно накапливается всякое
echo "что в /var занимает место:"
du -h --max-depth=1 /var 2>/dev/null | sort -hr | head -5
echo ""

# TODO: добавить анализ /usr

# размер текущей папки пользователя
echo "текущая папка пользователя:"
du -sh ~ 2>/dev/null

echo ""

# свободное место на основном диске
ROOT_FREE=$(df / | tail -1 | awk '{print $4}')
echo "свободно на /:" $(echo $ROOT_FREE | awk '{printf "%.1f GB", $1/1024/1024}')

echo ""
echo "анализ завершён"
