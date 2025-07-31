#!/bin/bash

# показываем инфу о системе 
# собрал разные команды в одно место
# версия 1.3

echo "---- информация о системе ----"
echo $(date)
echo ""

echo "СИСТЕМА:"
echo "ОС:" $(lsb_release -d | cut -f2)
echo "ядро:" $(uname -r)
echo "архитектура:" $(uname -m)
echo "хост:" $(hostname)
echo "аптайм:" $(uptime -p)
echo ""

echo "РЕСУРСЫ:"
echo "CPU:" $(nproc) "ядер"
echo "память:" $(free -h | grep Mem | awk '{print $2}')
echo "загрузка:" $(cat /proc/loadavg | cut -d' ' -f1-3)
echo ""

echo "ДИСКИ:"
df -h | grep /dev/
echo ""

echo "СЕТЬ:"
echo "IP:" $(hostname -I | awk '{print $1}')

# TODO: добавить проверку DNS

echo "интерфейсы:"
ip link show | grep '^[0-9]' | cut -d: -f2

echo ""

echo "ПРОЦЕССЫ:"
echo "всего:" $(ps aux | wc -l)
echo "пользователей:" $(who | wc -l)

echo ""

echo "последние логины:"
last -n 2

echo ""
echo "---- конец ----"
