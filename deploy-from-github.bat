@echo off
chcp 65001 >nul
color 0B

REM ==========================================
REM  ДЕПЛОЙ НА СЕРВЕР С GITHUB
REM ==========================================

echo.
echo ================================================================
echo   🚀 ДЕПЛОЙ НА СЕРВЕР С GITHUB
echo ================================================================
echo.

REM Настройки (измените на свои)
set GITHUB_REPO=https://github.com/RobSVR/Perps-info-tg-bot.git
set SERVER=ВАШ_IP_АДРЕС
set USER=root
set REMOTE_DIR=/opt/Perps-info-tg-bot

if "%1"=="" (
    echo Использование:
    echo   deploy-from-github.bat setup    - Первоначальная настройка на сервере
    echo   deploy-from-github.bat update   - Обновление бота на сервере
    echo.
    echo Сначала настройте переменные в этом файле:
    echo   SERVER - IP адрес вашего сервера
    echo   USER - пользователь для подключения (обычно root)
    echo.
    pause
    exit /b 1
)

if "%1"=="setup" (
    echo 📥 Первоначальная настройка на сервере...
    echo.
    
    echo Шаг 1: Клонирование репозитория на сервер...
    ssh %USER%@%SERVER% "cd /opt && rm -rf Perps-info-tg-bot && git clone %GITHUB_REPO% Perps-info-tg-bot"
    
    if %errorlevel% neq 0 (
        echo ❌ Ошибка при клонировании репозитория!
        pause
        exit /b 1
    )
    
    echo.
    echo Шаг 2: Установка Python зависимостей...
    ssh %USER%@%SERVER% "cd %REMOTE_DIR% && pip3 install -r requirements.txt"
    
    echo.
    echo Шаг 3: Проверка файла .env...
    ssh %USER%@%SERVER% "[ ! -f %REMOTE_DIR%/.env ] && echo '⚠️  Файл .env не найден! Создайте его на сервере.' || echo '✅ Файл .env существует'"
    
    echo.
    echo Шаг 4: Установка systemd сервиса...
    ssh %USER%@%SERVER% "sudo cp %REMOTE_DIR%/perps-bot.service /etc/systemd/system/ && sudo systemctl daemon-reload && sudo systemctl enable perps-bot.service"
    
    echo.
    echo ✅ Первоначальная настройка завершена!
    echo.
    echo ⚠️  Не забудьте:
    echo   1. Создать файл .env на сервере с токеном бота
    echo   2. Запустить бота: ssh %USER%@%SERVER% "sudo systemctl start perps-bot"
    echo.
    pause
    exit /b 0
)

if "%1"=="update" (
    echo 🔄 Обновление бота на сервере...
    echo.
    
    echo Шаг 1: Обновление кода с GitHub на сервере...
    ssh %USER%@%SERVER% "cd %REMOTE_DIR% && git pull origin main"
    
    if %errorlevel% neq 0 (
        echo ❌ Ошибка при обновлении кода!
        pause
        exit /b 1
    )
    
    echo.
    echo Шаг 2: Установка новых зависимостей (если есть)...
    ssh %USER%@%SERVER% "cd %REMOTE_DIR% && pip3 install -r requirements.txt"
    
    echo.
    echo Шаг 3: Перезапуск бота...
    ssh %USER%@%SERVER% "sudo systemctl restart perps-bot"
    
    echo.
    echo Шаг 4: Проверка статуса бота...
    ssh %USER%@%SERVER% "sudo systemctl status perps-bot --no-pager"
    
    echo.
    echo ✅ Бот обновлен и перезапущен!
    echo.
    echo 📋 Полезные команды:
    echo   Статус:     ssh %USER%@%SERVER% "sudo systemctl status perps-bot"
    echo   Логи:       ssh %USER%@%SERVER% "sudo journalctl -u perps-bot -f"
    echo   Остановка:  ssh %USER%@%SERVER% "sudo systemctl stop perps-bot"
    echo   Запуск:     ssh %USER%@%SERVER% "sudo systemctl start perps-bot"
    echo.
    pause
    exit /b 0
)

echo ❌ Неизвестная команда: %1
echo Используйте: setup или update
pause

