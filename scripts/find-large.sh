#!/bin/bash

# ищем большие файлы которые жрут место  
# когда диск заполнился надо найти что удалить
# v1.1

echo "=== поиск больших файлов ==="
echo "запуск:" $(date)
echo ""

# проверяем текущее состояние дисков
echo "состояние дисков:"
df -h | grep -v tmpfs | grep -v udev
echo ""

# ищем файлы больше 100MB в системе (исключаем /proc /sys)
echo "файлы больше 100MB:"
find / -type f -size +100M -not -path "/proc/*" -not -path "/sys/*" -not -path "/dev/*" 2>/dev/null | head -10 | while read file; do
    size=$(du -h "$file" 2>/dev/null | cut -f1)
    echo "$size - $file"
done

echo ""

# топ директорий по размеру в /var (там обычно накапливается мусор)
echo "самые большие папки в /var:"
du -h /var/* 2>/dev/null | sort -hr | head -5

echo ""

# ищем старые файлы в /tmp
echo "старые файлы в /tmp:"
find /tmp -type f -mtime +7 2>/dev/null | wc -l | awk '{print $1 " файлов старше недели"}'

# TODO: добавить поиск дубликатов файлов

echo ""

# логи которые могут быть большими
echo "размер папки с логами:"
if [ -d /var/log ]; then
    du -sh /var/log 2>/dev/null
else
    echo "/var/log недоступна"
fi

echo ""
echo "поиск завершён"
