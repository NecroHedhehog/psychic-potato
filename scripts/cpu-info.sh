#!/bin/bash

# показываем подробную информацию о процессоре
# полезно для понимания возможностей сервера
# версия 1.0

echo "=== информация о процессоре ==="
echo $(date)
echo ""

# основная информация о CPU
echo "процессор:"
grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^ *//'
echo ""

# количество ядер и потоков
echo "ядра и потоки:"
echo "физических ядер:" $(grep "cpu cores" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^ *//')
echo "логических процессоров:" $(nproc)
echo "физических процессоров:" $(grep "physical id" /proc/cpuinfo | sort -u | wc -l)
echo ""

# архитектура и частота
echo "характеристики:"
echo "архитектура:" $(uname -m)
grep "cpu MHz" /proc/cpuinfo | head -1 | awk -F: '{printf "частота: %.0f MHz\n", $2}'
echo ""

# поддерживаемые флаги (основные)
echo "основные возможности:"
FLAGS=$(grep "flags" /proc/cpuinfo | head -1 | cut -d: -f2)
echo $FLAGS | grep -q "vmx\|svm" && echo "виртуализация: поддерживается" || echo "виртуализация: не поддерживается"
echo $FLAGS | grep -q "aes" && echo "AES шифрование: да" || echo "AES шифрование: нет"
echo $FLAGS | grep -q "avx" && echo "AVX инструкции: да" || echo "AVX инструкции: нет"
echo ""

# TODO: добавить информацию о кэше

# текущая загрузка и температура (если доступно)
echo "текущее состояние:"
echo "загрузка:" $(cat /proc/loadavg | cut -d' ' -f1-3)

# температура если доступна
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
    echo "температура:" $((TEMP/1000))"°C"
else
    echo "температура: недоступна"
fi

echo ""

# использование CPU за последнюю минуту
echo "использование CPU:"
top -bn1 | grep "Cpu(s)" | awk '{print "пользователь: " $2 ", система: " $4 ", ожидание: " $6}'

echo ""
echo "информация собрана"
