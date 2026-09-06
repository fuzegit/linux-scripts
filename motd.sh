#!/bin/bash

# ==========================================
# Fuze MOTD Script
# Размещение: /etc/profile.d/motd.sh
# Использование: curl -fsSL "https://raw.githubusercontent.com/fuzegit/linux-scripts/refs/heads/main/motd.sh" -o "/etc/profile.d/motd.sh" && chmod +x "/etc/profile.d/motd.sh"
# или сразу редуктирование: curl -fsSL "https://raw.githubusercontent.com/fuzegit/linux-scripts/refs/heads/main/motd.sh" -o "/etc/profile.d/motd.sh" && chmod +x "/etc/profile.d/motd.sh" && nano "/etc/profile.d/motd.sh"
# Вместо My Server напишите своё понятное имя сервера
# ==========================================

SERVER_NAME="My Server"

# 1. Проверка прав: выходим, если пользователь не root
if [ "$(whoami)" != "root" ]; then
    exit 0
fi

# 2. Настройка цветов (с проверкой поддержки tput)
if command -v tput &> /dev/null; then
    CYAN=$(tput setaf 6)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    RED=$(tput setaf 1)
    RESET=$(tput sgr0)
else
    CYAN=""
    GREEN=""
    YELLOW=""
    RED=""
    RESET=""
fi

# 3. Чистка экрана (прокрутка вверх на высоту терминала)
LINES=$(stty size | awk '{print $1}')
if [ -n "$LINES" ] && [ "$LINES" -gt 0 ] 2>/dev/null; then
    for ((i=0; i<LINES; i++)); do
        echo ''
    done
    tput cuu $LINES 2>/dev/null
fi

# 4. Сбор информации о системе
source /etc/os-release 2>/dev/null
OS_NAME="${PRETTY_NAME:-Linux}"

# 5. Сетевая информация (IPv4/IPv6) - ИСПРАВЛЕНО
# Получаем все IPv4 адреса
IPv4_ALL=$(ip -4 addr show | awk '/inet / {print $2}' | cut -d/ -f1 | grep -v "^127\.0\.0\.1$" | head -n 10)
# Получаем все IPv6 адреса
IPv6_ALL=$(ip -6 addr show | awk '/inet6 / {print $2}' | cut -d/ -f1 | grep -v "^::1$" | head -n 10)

# Берем первый из всех доступных (основной)
IPv4=$(echo "$IPv4_ALL" | head -n 1)
IPv6=$(echo "$IPv6_ALL" | head -n 1)

# 6. Системные метрики
UPTIME_STR=$(uptime -p 2>/dev/null | sed 's/up //')
LOAD_AVG=$(cut -d ' ' -f1 /proc/loadavg)
RAM_AVAILABLE_MB=$(free -m | awk '/^Mem/ {print $7}')
DISK_FREE_GB=$(df -h / | awk 'NR==2 {print $4}')

# 7. Клиентский IP (при SSH-соединении)
if [ -n "$SSH_CLIENT" ]; then
    CLIENT_IP=$(echo "$SSH_CLIENT" | awk '{print $1}')
else
    CLIENT_IP="Локальная сессия"
fi

# 8. Проверка обновлений (быстрая, работает по кэшу apt)
# Принудительно используем английский язык для стабильного парсинга
UPDATES_COUNT=$(LC_ALL=C apt list --upgradable 2>/dev/null | grep -c upgradable || true)
# Убеждаемся, что это число
if ! [[ "$UPDATES_COUNT" =~ ^[0-9]+$ ]]; then
    UPDATES_COUNT=0
fi

# 9. Активные сессии
ACTIVE_SESSIONS=$(who 2>/dev/null)

# ==========================================
# Вывод информации
# ==========================================

echo
echo -e "${CYAN}=============================================================="
echo -e "${GREEN}                    ${SERVER_NAME}                           "
echo -e "${CYAN}=============================================================="
echo

# Информация о системе
echo -e "  Операционная система:  ${GREEN}${OS_NAME}${RESET}"
echo

# Сеть
if [ -n "$IPv4_ALL" ]; then
    FIRST_IPV4=$(echo "$IPv4_ALL" | head -n 1)
    OTHER_IPV4=$(echo "$IPv4_ALL" | tail -n +2)
    echo -e "  IPv4 адреса:          ${GREEN}${FIRST_IPV4}${RESET}"
    if [ -n "$OTHER_IPV4" ]; then
        echo "$OTHER_IPV4" | while read -r ip; do
            echo -e "                        ${GREEN}${ip}${RESET}"
        done
    fi
fi
if [ -n "$IPv6_ALL" ]; then
    FIRST_IPV6=$(echo "$IPv6_ALL" | head -n 1)
    OTHER_IPV6=$(echo "$IPv6_ALL" | tail -n +2)
    echo -e "  IPv6 адреса:          ${GREEN}${FIRST_IPV6}${RESET}"
    if [ -n "$OTHER_IPV6" ]; then
        echo "$OTHER_IPV6" | while read -r ip; do
            echo -e "                        ${GREEN}${ip}${RESET}"
        done
    fi
fi
echo

# Нагрузка и аптайм
echo -e "  Аптайм:               ${YELLOW}${UPTIME_STR:-Неизвестно}${RESET}"
echo -e "  Нагрузка (1 мин):     ${YELLOW}${LOAD_AVG:-Неизвестно}${RESET}"
echo

# Ресурсы
echo -e "  Доступная RAM:        ${GREEN}${RAM_AVAILABLE_MB:-?} MB${RESET}"
echo -e "  Свободное место на /: ${GREEN}${DISK_FREE_GB:-?}${RESET}"
echo

# Обновления
if [ "$UPDATES_COUNT" -gt 0 ]; then
    echo -e "  Доступных обновлений: ${YELLOW}${UPDATES_COUNT}${RESET}"
else
    echo -e "  Доступных обновлений: ${GREEN}Нет${RESET}"
fi
echo

# Активные сессии
if [ -n "$ACTIVE_SESSIONS" ]; then
    echo -e "  ${GREEN}Активные сессии:${RESET}"
    echo "$ACTIVE_SESSIONS" | while read -r user tty time ip; do
        if [ -n "$ip" ]; then
            echo -e "    • ${user} на ${tty} ${ip}"
        else
            echo -e "    • ${user} на ${tty}"
        fi
    done
    echo
fi

# Клиент
echo -e "  Ваш IP (SSH):        ${RED}${CLIENT_IP}${RESET}"
echo
echo -e "${CYAN}=============================================================="
echo
echo -e "$RESET"
