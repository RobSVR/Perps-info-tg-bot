@echo off
chcp 65001 >nul
color 0A
echo.
echo ================================================================
echo   ⚡ БЫСТРОЕ ОБНОВЛЕНИЕ BOTА НА СЕРВЕРЕ ⚡
echo ================================================================
echo.

REM ==========================================
REM  НАСТРОЙКИ - ИЗМЕНИТЕ НА ВАШИ ДАННЫЕ
REM ==========================================
set SERVER=ВАШ_IP_АДРЕС
set USER=root
set REMOTE_DIR=/opt/Perps-info-tg-bot

REM Проверка, что IP указан
if "%SERVER%"=="ВАШ_IP_АДРЕС" (
    echo [ОШИБКА] Сначала укажите IP адрес сервера в этом файле!
    echo.
    echo Откройте update-and-deploy.bat в блокноте и измените:
    echo set SERVER=ВАШ_IP_АДРЕС
    echo.
    pause
    exit /b 1
)

echo 📡 Сервер: %USER%@%SERVER%
echo 📁 Папка: %REMOTE_DIR%
echo.

echo ========================================
echo 📤 ЗАГРУЗКА ФАЙЛОВ НА СЕРВЕР...
echo ========================================
echo.

REM Загрузка файлов
scp bot.py %USER%@%SERVER%:%REMOTE_DIR%/
scp config.py %USER%@%SERVER%:%REMOTE_DIR%/
scp requirements.txt %USER%@%SERVER%:%REMOTE_DIR%/

if exist perps-bot.service (
    scp perps-bot.service %USER%@%SERVER%:%REMOTE_DIR%/
)

echo.
echo ✅ Файлы загружены!

echo.
echo ========================================
echo 🔄 ПЕРЕЗАПУСК БОТА...
echo ========================================
echo.

REM Перезапуск бота
ssh %USER%@%SERVER% "systemctl restart perps-bot"

echo.
echo ========================================
echo 📊 ПРОВЕРКА СТАТУСА...
echo ========================================
echo.

REM Проверка статуса
ssh %USER%@%SERVER% "systemctl status perps-bot --no-pager -l"

echo.
echo ========================================
echo ✅ БОТ УСПЕШНО ОБНОВЛЕН!
echo ========================================
echo.
echo Команды для управления ботом:
echo   Просмотр логов: ssh %USER%@%SERVER% "journalctl -u perps-bot -f"
echo   Перезапуск:     ssh %USER%@%SERVER% "systemctl restart perps-bot"
echo   Статус:         ssh %USER%@%SERVER% "systemctl status perps-bot"
echo.
pause

