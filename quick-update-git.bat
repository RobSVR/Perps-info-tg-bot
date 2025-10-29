@echo off
chcp 65001 >nul
color 0B
cls

echo.
echo ================================================================
echo   ⚡ БЫСТРОЕ ОБНОВЛЕНИЕ ЧЕРЕЗ GIT
echo ================================================================
echo.

REM ==========================================
REM  НАСТРОЙКИ - ИЗМЕНИТЕ НА ВАШИ ДАННЫЕ
REM ==========================================
set SERVER=45.132.19.34
set USER=root
set GITHUB_REPO=https://github.com/RobSVR/Perps-info-tg-bot.git

REM Проверка настроек
if "%SERVER%"=="ВАШ_IP_АДРЕС_ЗДЕСЬ" (
    echo [ОШИБКА] Укажите IP адрес сервера!
    echo Откройте quick-update-git.bat и измените: set SERVER=...
    pause
    exit /b 1
)

if "%GITHUB_REPO%"=="https://github.com/ВАШ_USERNAME/Perps-info-tg-bot.git" (
    echo [ОШИБКА] Укажите ссылку на GitHub репозиторий!
    echo Откройте quick-update-git.bat и измените: set GITHUB_REPO=...
    pause
    exit /b 1
)

echo 📡 Сервер: %USER%@%SERVER%
echo 📦 Репозиторий: %GITHUB_REPO%
echo.

REM Параметры или команда
if "%1"=="init" (
    echo 🔧 Первоначальная настройка Git...
    echo.
    
    echo Шаг 1: Инициализация Git
    git init
    git remote remove origin 2>nul
    git remote add origin %GITHUB_REPO%
    
    echo.
    echo Шаг 2: Первый коммит (если нужно)
    if not exist .git (git init)
    git add .
    git commit -m "Initial setup" 2>nul
    
    echo.
    echo Шаг 3: Загрузка на GitHub
    git branch -M main
    git push -u origin main
    
    echo.
    echo Шаг 4: Клонирование на сервер
    ssh %USER%@%SERVER% "cd /opt && git clone %GITHUB_REPO% Perps-info-tg-bot"
    ssh %USER%@%SERVER% "cd /opt/Perps-info-tg-bot && pip3 install -r requirements.txt"
    ssh %USER%@%SERVER% "cd /opt/Perps-info-tg-bot && cp perps-bot.service /etc/systemd/system/ && systemctl daemon-reload && systemctl enable perps-bot && systemctl start perps-bot"
    
    echo.
    echo ✅ Настройка завершена!
    echo Теперь используйте: quick-update-git.bat для обновлений
    pause
    exit /b 0
)

echo 📤 Обновление кода...
echo.

REM Добавляем все изменения
git add bot.py config.py *.py 2>nul
if exist *.md git add *.md

echo Введите описание обновления (или нажмите Enter для "Update"):
set /p commit_msg=
if "%commit_msg%"=="" set commit_msg=Update

echo.
echo Создание коммита...
git commit -m "%commit_msg%" 2>nul

echo.
echo Отправка на GitHub...
git push

echo.
echo Обновление на сервере...
ssh %USER%@%SERVER% "cd /opt/Perps-info-tg-bot && git pull"

echo.
echo Перезапуск бота...
ssh %USER%@%SERVER% "systemctl restart perps-bot"

echo.
echo Проверка статуса...
timeout /t 2 /nobreak >nul
ssh %USER%@%SERVER% "systemctl status perps-bot --no-pager -l"

echo.
echo ========================================
echo ✅ БОТ ОБНОВЛЕН!
echo ========================================
echo.
pause


