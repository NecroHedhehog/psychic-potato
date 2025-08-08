#!/bin/bash

# управление пользователями на Ubuntu серверах
# создание пользователей с правильными настройками безопасности
# версия 1.0

echo "=== управление пользователями ==="
echo $(date)
echo ""

# проверяем права root
if [[ $EUID -ne 0 ]]; then
   echo "этот скрипт нужно запускать от root"
   echo "используйте: sudo $0"
   exit 1
fi

# функция создания пользователя
create_user() {
    local username=$1
    local add_sudo=$2
    
    if id "$username" &>/dev/null; then
        echo "пользователь $username уже существует"
        return 1
    fi
    
    echo "создаем пользователя: $username"
    
    # создаем пользователя с домашней папкой
    useradd -m -s /bin/bash "$username"
    
    # устанавливаем пароль (просим ввести)
    echo "установите пароль для $username:"
    passwd "$username"
    
    # добавляем в группы
    usermod -a -G users "$username"
    
    if [[ "$add_sudo" == "y" ]]; then
        usermod -a -G sudo "$username"
        echo "$username добавлен в группу sudo"
    fi
    
    # создаем .ssh папку с правильными правами
    mkdir -p /home/"$username"/.ssh
    chmod 700 /home/"$username"/.ssh
    chown "$username":"$username" /home/"$username"/.ssh
    
    # создаем пустой authorized_keys
    touch /home/"$username"/.ssh/authorized_keys
    chmod 600 /home/"$username"/.ssh/authorized_keys
    chown "$username":"$username" /home/"$username"/.ssh/authorized_keys
    
    echo "пользователь $username создан успешно"
    echo "SSH папка настроена"
}

# функция удаления пользователя
delete_user() {
    local username=$1
    
    if ! id "$username" &>/dev/null; then
        echo "пользователь $username не найден"
        return 1
    fi
    
    echo "удаляем пользователя: $username"
    echo "это удалит домашнюю папку и все файлы!"
    read -p "продолжить? (y/N): " confirm
    
    if [[ "$confirm" == "y" ]]; then
        userdel -r "$username"
        echo "пользователь $username удален"
    else
        echo "отменено"
    fi
}

# функция показа информации о пользователе
show_user_info() {
    local username=$1
    
    if ! id "$username" &>/dev/null; then
        echo "пользователь $username не найден"
        return 1
    fi
    
    echo "информация о пользователе: $username"
    echo "UID: $(id -u $username)"
    echo "группы: $(groups $username)"
    echo "домашняя папка: $(eval echo ~$username)"
    echo "последний вход:"
    last -n 1 "$username"
}

# основное меню
echo "выберите действие:"
echo "1) создать пользователя"
echo "2) удалить пользователя" 
echo "3) показать информацию о пользователе"
echo "4) показать всех пользователей"
echo "5) выход"
echo ""

read -p "ваш выбор (1-5): " choice

case $choice in
    1)
        read -p "имя пользователя: " username
        read -p "добавить права sudo? (y/N): " sudo_rights
        create_user "$username" "$sudo_rights"
        ;;
    2)
        read -p "имя пользователя для удаления: " username
        delete_user "$username"
        ;;
    3)
        read -p "имя пользователя: " username
        show_user_info "$username"
        ;;
    4)
        echo "пользователи в системе:"
        cat /etc/passwd | grep '/home' | cut -d: -f1
        ;;
    5)
        echo "завершение работы"
        exit 0
        ;;
    *)
        echo "неверный выбор"
        exit 1
        ;;
esac

echo ""
echo "операция завершена"
