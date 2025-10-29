@echo off
chcp 65001 >nul
color 0B

REM ==========================================
REM  НАСТРОЙКИ
REM ==========================================
set GITHUB_REPO=https://github.com/ВАШ_USERNAME/Perps-info-tg-bot.git
set SERVER=ВАШ_IP_АДРЕС
set USER=root

echo.
echo ================================================================
echo   🚀 ДЕПЛОЙ ЧЕРЕЗ GIT (РЕКОМЕНДУЕТСЯ)
echo ================================================================
echo.

if "%1"=="" (
    echo Использование:
    echo   deploy-with-git.bat push    - обновить на сервере
    echo   deploy-with-git.bat setup   - первый раз на сервере
    echo.
    echo Сначала:
    echo 1. Создайте репозиторий на GitHub
    echo 2. Укажите ссылку на репозиторий в этом файле
    echo 3. Запустите: deploy-with-git.bat setup
    echo.
    pause
    exit /b 1
)

if "%1"=="setup" (
    echo 📥 Первоначальная настройка...
    echo.
    
    echo Шаг 1: Загрузка кода на GitHub
    git remote add origin %GITHUB_REPO%
    git push -u origin main
    
    echo.
    echo Шаг 2: Настройка сервера
    ssh %USER%@%SERVER% "cd /opt && git clone %GITHUB_REPO% Perps-info-tg-bot"
    ssh %USER%@%SERVER% "cd /opt/Perps-info-tg-bot && pip3 install -r requirements.txt"
    
    echo.
    echo ✅ Настройка завершена!
    echo Теперь используйте: deploy-with-git.bat push
    pause
    exit /b 0
)

if "%1"=="push" (
    echo 📤 Обновление кода...
    echo.
    
    git add .
    git commit -m "Update bot"
    git push
    
    echo.
    echo 🔄 Обновление на сервере...
    ssh %USER%@%SERVER% "cd /opt/Perps-info-tg-bot && git pull"
    
    echo.
    echo 🔄 Перезапуск бота...
    ssh %USER%@%SERVER% "systemctl restart perps-bot"
    
    echo.
    echo ✅ Готово!
    pause
    exit /b 0
)

echo Неизвестная команда: %1
pause

