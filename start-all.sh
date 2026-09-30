#!/bin/bash
# ==============================================================================
# 🚀 УНИВЕРСАЛЬНЫЙ СКРИПТ УМНОГО ЗАПУСКА ПОЛИГОНА PWD-POLYGONE (EUREKA HEALTH CHECK)
# ==============================================================================
set -e

# 1. Функция ожидания открытия базовых системных портов (для баз и Еврики)
wait_for_port() {
    local host=$1
    local port=$2
    local service_name=$3
    local timeout=60
    local count=0

    echo -n "⏳ Ожидаем готовности порта $port для [$service_name]..."
    while ! (echo > /dev/tcp/"$host"/"$port") > /dev/null 2>&1; do
        sleep 1
        count=$((count + 1))
        echo -n "."
        if [ "$count" -ge "$timeout" ]; then
            echo -e "\n⚠️  Превышено время ожидания ($timeout сек) для $service_name на порту $port!"
            return 1
        fi
    done
    echo -e "\n✅ Сервис [$service_name] открыл порт $port!"
}

# 2. Профессиональная функция проверки статуса приложения ВНУТРИ ЕВРИКИ
wait_for_eureka_status() {
    local app_name=$1
    local timeout=60
    local count=0

    echo -n "🌐 [Eureka Client]: Ждем, пока микросервис [$app_name] получит статус UP..."
    
    while true; do
        # Делаем запрос к REST API Еврики, запрашивая JSON-формат
        local response=$(curl -s -H "Accept: application/json" http://localhost:1111/eureka/apps/"$app_name" 2>/dev/null || true)
        
        # Проверяем, содержит ли ответ заветную строчку со статусом UP
        if [[ "$response" == *"\"status\":\"UP\""* ]] || [[ "$response" == *"\"status\" : \"UP\""* ]]; then
            echo -e "\n🟢 УСПЕХ! [$app_name] официально зарегистрирован в Еврике со статусом UP!"
            return 0
        fi

        sleep 2
        count=$((count + 2))
        echo -n "."
        
        if [ "$count" -ge "$timeout" ]; then
            echo -e "\n⚠️  Таймаут ($timeout сек) ожидания статуса UP для [$app_name] в реестре Eureka."
            echo "Продолжаем запуск цепочки..."
            return 1
        fi
    done
}

echo "========================================================================"
echo "🎯 Начинаем контролируемый запуск микросервисной архитектуры..."
echo "========================================================================"

# --- ШАГ 1: Базы данных ---
echo -e "\n📋 [ЭТАП 1]: Запуск систем хранения данных..."
docker compose up -d postgres-db mongodb

wait_for_port "127.0.0.1" 5432 "PostgreSQL"
wait_for_port "127.0.0.1" 27017 "MongoDB"

# --- ШАГ 2: Сервер регистрации (Eureka) ---
echo -e "\n📋 [ЭТАП 2]: Запуск центрального регистратора..."
docker compose up -d eureka-server

wait_for_port "127.0.0.1" 1111 "Eureka Server"
echo "⏳ Даем Еврике 5 секунд форы на стабилизацию..."
sleep 5

# --- ШАГ 3: Бизнес-микросервисы и Тетрис ---
echo -e "\n📋 [ЭТАП 3]: Запуск игровых ядер и движков..."
docker compose up -d users-service game-service mongo-service tetris-game

# Настоящие, «умные» проверки статуса готовности из реестра Еврики!
# (Имена приложений передаются в верхнем регистре, как их видит Spring Cloud)
wait_for_eureka_status "USERS-SERVICE"
wait_for_eureka_status "GAME-SERVICE"
wait_for_eureka_status "MONGO-SERVICE"
wait_for_eureka_status "RAGING-HORSE-TETRIS-4-1"

# --- ШАГ 4: Сетевой Шлюз (Бордюр безопасности) ---
echo -e "\n📋 [ЭТАП 4]: Открываем входной шлюз для пользователей..."
docker compose up -d gateway-service

wait_for_port "127.0.0.1" 5555 "API Gateway"

echo "========================================================================"
echo "🎉 ПОБЕДА! Все слои архитектуры развернуты и синхронизированы через Eureka!"
echo "========================================================================"
docker compose ps --format "table {{.Names}}\t{{.Status}}"
