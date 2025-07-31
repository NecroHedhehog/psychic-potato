#!/bin/bash

# проверяем сеть работает ли
# чтобы понять где проблема с интернетом
# версия 1.1

echo "=== тест сети ==="
echo $(date)
echo ""

echo "конфигурация:"
echo "мой IP:" $(hostname -I | awk '{print $1}')
echo "шлюз:" $(ip route | grep default | awk '{print $3}')
echo "DNS:"
cat /etc/resolv.conf | grep nameserver
echo ""

echo "проверяем доступность:"

# пингуем шлюз
GATEWAY=$(ip route | grep default | awk '{print $3}')
ping -c 2 $GATEWAY && echo "шлюз доступен" || echo "шлюз недоступен"

# пингуем DNS
ping -c 2 8.8.8.8 && echo "DNS google работает" || echo "DNS не работает"

# пингуем сайт
ping -c 2 google.com && echo "интернет есть" || echo "интернета нет"

echo ""

# TODO: добавить traceroute

echo "тест скорости:"
echo "качаем тестовый файл..."

# простой тест скорости
START=$(date +%s)
curl -s http://speedtest.tele2.net/1MB.zip > /dev/null
END=$(date +%s)
DURATION=$((END - START))

if [ $DURATION -gt 0 ]; then
    echo "время загрузки 1МБ:" $DURATION "сек"
else
    echo "очень быстро"
fi

echo ""
echo "активных соединений:" $(ss -t | grep ESTAB | wc -l)

echo ""
echo "тест завершён"
