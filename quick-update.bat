@echo off
chcp 65001 >nul
color 0A
cls

echo.
echo ================================================================
echo   ⚡ БЫСТРОЕ ОБНОВЛЕНИЕ БОТА НА СЕРВЕРЕ ⚡
echo ================================================================
echo.

REM ==========================================
REM  НАСТРОЙКИ - ИЗМЕНИТЕ НА ВАШИ ДАННЫЕ
REM ==========================================
set SERVER=ВАШ_IP_АДРЕС_ЗДЕСЬ
set USER=root
set REMOTE_DIR=/opt/Perps-info-tg-bot

REM Проверка, что IP указан
if "%SERVER%"=="ВАШ_IP_АДРЕС_ЗДЕСЬ" (
    echo [ОШИБКА] Сначала укажите IP адрес сервера!
    echo.
    echo Откройте quick-update.bat в блокноте и измените:
    echo     set SERVER=ВАШ_IP_АДРЕС_ЗДЕСЬ
    echo.
    echo Замените ВАШ_IP_АДРЕС_ЗДЕСЬ на реальный IP (например: 123.45.67.89)
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

REM Загрузка файлов (улучшенная версия)
scp -q bot.py %USER%@%SERVER%:%REMOTE_DIR%/ 2>nul
if errorlevel 1 (
    echo ⚠️ Не удалось загрузить bot.py
    echo Проверьте подключение к серверу
) else (
    echo ✅ bot.py загружен
)

scp -q config.py %USER%@%SERVER%:%REMOTE_DIR%/ 2>nul
if errorlevel 1 (
    echo ⚠️ Не удалось загрузить config.py
) else (
    echo ✅ config.py загружен
)

if exist requirements.txt (
    scp -q requirements.txt %USER%@%SERVER%:%REMOTE_DIR%/ 2>nul
    if errorlevel 1 (
        echo ⚠️ Не удалось загрузить requirements.txt
    ) else (
        echo ✅ requirements.txt загружен
    )
)

echo.
echo ========================================
echo 🔄 ПЕРЕЗАПУСК БОТА...
echo ========================================
echo.

REM Перезапуск бота
ssh %USER%@%SERVER% "systemctl restart perps-bot" 2>nul
if errorlevel 1 (
    echo ⚠️ Ошибка перезапуска бота
) else (
    echo ✅ Бот перезапущен
)

echo.
echo ========================================
echo 📊 ПРОВЕРКА СТАТУСА...
echo ========================================
echo.

REM Проверка статуса
timeout /t 2 /nobreak >nul
ssh %USER%@%SERVER% "systemctl status perps-bot --no-pager -l" 2>nul

echo.
echo ========================================
echo ✅ ГОТОВО!
echo ========================================
echo.
echo 💡 Полезные команды:
echo   Логи:      ssh %USER%@%SERVER% "journalctl -u perps-bot -f"
echo   Перезапуск: ssh %USER%@%SERVER% "systemctl restart perps-bot"
echo   Статус:     ssh %USER%@%SERVER% "systemctl status perps-bot"
echo.
pause


