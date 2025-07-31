#!/bin/bash

# проверка портов которые слушают
# надо понимать что открыто для безопасности
# версия 1.0

echo "=== проверяем порты ==="
echo "время:" $(date)
echo ""

echo "TCP порты:"
# вывод всех слушающих портов
ss -tlnp | grep LISTEN | awk '{print $4 " " $7}'
echo ""

echo "UDP:"
ss -ulnp | awk '{print $4 " " $6}'
echo ""

# TODO: добавить фильтрацию по процессам

echo "соединения:"
echo "активных:" $(ss -t | grep ESTAB | wc -l)
echo ""

# основные порты которые часто нужны
echo "стандартные службы:"
ss -tln | grep :22 && echo "SSH работает" || echo "SSH выключен"
ss -tln | grep :80 && echo "HTTP работает" || echo "HTTP выключен"  
ss -tln | grep :443 && echo "HTTPS работает" || echo "HTTPS выключен"

echo ""
echo "проверка завершена"
